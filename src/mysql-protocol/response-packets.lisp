;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                  ;;;
;;; Free Software published under an MIT-like license. See LICENSE   ;;;
;;;                                                                  ;;;
;;; Copyright (c) 2012 Google, Inc.  All rights reserved.            ;;;
;;;                                                                  ;;;
;;; Original author: Alejandro Sedeño                                ;;;
;;;                                                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :mysqlnd)

;;; 15.1.3. Generic Response Packets

(define-packet response-ok
    ((tag :mysql-type (integer 1) :value 0 :transient t :bind nil)
     (affected-rows :mysql-type (integer :lenenc))
     (last-insert-id :mysql-type (integer :lenenc))
     (status-flags :mysql-type (integer 2)
                   :predicate (mysql-has-some-capability
                               #.(logior $mysql-capability-client-protocol-41
                                         $mysql-capability-client-transactions)))
     (warnings :mysql-type (integer 2)
               :predicate (mysql-has-capability $mysql-capability-client-protocol-41))
     (info :mysql-type (string :eof))))

(define-packet response-error
    ((tag :mysql-type (integer 1) :value #xff :transient t :bind nil)
     (error-code :mysql-type (integer 2))
     ;; This really a string, but we're just checking to see it's a #\#
     (state-marker :mysql-type (integer 1)
                   :predicate (mysql-has-capability $mysql-capability-client-protocol-41)
                   :value #.(char-code #\#)
                   :transient t
                   :bind nil)
     (sql-state :mysql-type (string 5)
                :predicate (mysql-has-capability $mysql-capability-client-protocol-41))
     (error-message :mysql-type (string :eof))))

(define-packet response-end-of-file
    ((tag :mysql-type (integer 1) :value #xfe :transient t :bind nil)
     (warning-count :mysql-type (integer 2)
                    :predicate (mysql-has-capability $mysql-capability-client-protocol-41))
     (status-flags :mysql-type (integer 2)
                   :predicate (mysql-has-capability $mysql-capability-client-protocol-41))))

(defun parse-response (payload)
  (case (aref payload 0)
    (#x00 (parse-response-ok payload))
    (#xfe (parse-response-end-of-file payload))
    (#xff (parse-response-error payload))))