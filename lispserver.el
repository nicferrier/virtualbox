;;; lispserver.el --- quick hack webserver for my virtualbox change

;; Copyright (C) 2017  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: lisp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'elnode)

(defun virtualbox-handler (request)
  (let ((params (elnode-http-params request)))
    ;; Just some logging
    (with-current-buffer (get-buffer-create "*virtualbox-log*")
      (princ (format "%s %s %S\n"
                     (current-time-string)
                     (elnode-http-pathinfo request)
                     params)
             (current-buffer)))
    ;; Now the handling
    (if (not (equal "0f328ae31463a76e40ed5421331c3467ca4fa6f2" (kva "digest" params)))
        (elnode-send-status request 400)
        ;; Else send something good
        (elnode-http-start request 400 '("Content-type" "text/html"))
        (elnode-http-return request "<html><h1>hello</h1></html>\n"))))

(defun virtualbox ()
  (interactive)
  (elnode-start 'virtualbox-handler :port 8009))

(provide 'lispserver)

;;; lispserver.el ends here
