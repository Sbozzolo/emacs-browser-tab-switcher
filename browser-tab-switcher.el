;;; browser-tab-switcher.el --- Switch EXWM browser windows -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Gabriele Bozzola
;;
;; Author: Gabriele Bozzola <https://github.com/sbozzolo>
;; Maintainer: Gabriele Bozzola <sbozzolator@gmail.com>
;; Created: December 07, 2020
;; Modified: December 07, 2020
;; Version: 1.0.0
;; Keywords: convenience
;; Prefix: browser-tab-switcher
;; Homepage: https://github.com/sbozzolo/emacs-browser-tab-switcher
;; Package-Requires: ((emacs "25.1") (exwm "0.12"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://WWW.gnu.org/licenses/>.

;;; Commentary:
;;
;;  description
;;
;;; Code:

(require 'subr-x)

(defcustom browser-tab-switcher-new-window-command
  "brave-browser --app=https://www.google.com"
  "Command to open a new browser window."
  :type 'string
  :group 'browser-tab-switcher)

(defcustom browser-tab-switcher-buffer-name-prefix "(Brave)"
  "Prefix to identify browser windows."
  :type 'string
  :group 'browser-tab-switcher)

(defun browser-tab-switcher--is-browser-window-p (buffer)
  "Return t if buffer BUFFER is a browser window.

This is done by checking the `major-mode' and the name."
  (and (eq (buffer-local-value 'major-mode buffer) 'exwm-mode)
       (string-prefix-p browser-tab-switcher-buffer-name-prefix
                        (buffer-name buffer))))

(defun browser-tab-switcher--get-browser-windows ()
  "List all the (other) VTerm buffers.

List all the browser windows, if the current one is a browser window,
exclude it."
  (seq-filter #'browser-tab-switcher--is-browser-window-p
              (delq (current-buffer) (buffer-list))))

(defun browser-tab-switcher-new-window ()
  "Open a new window with `browser-tab-switcher-new-window-command'."
  (start-process-shell-command
   browser-tab-switcher-new-window-command
   nil
   browser-tab-switcher-new-window-command))

(defun browser-tab-switcher--create-or-switch (browser-windows)
  "Ask the user to pick one in BROWSER-WINDOWS or to create New window."
  (let ((user-choice (completing-read "Select window: "
                                      (cons "New window" browser-windows)
                                      nil t)))
    (if (string= user-choice "New window")
        (browser-tab-switcher-new-window)
      (pop-to-buffer-same-window
       (concat
        browser-tab-switcher-buffer-name-prefix " " user-choice)))))

;; This function was inspired by Mike Zamansky's eshell-switcher
;; https://cestlaz.github.io/post/using-emacs-66-eshell-elisp/
;;;###autoload
(defun browser-tab-switcher (&optional arg)
  "Switch to a browser window or create a new one.

If there are no browser window, create a new one.
If the current buffer is the only browser windows, create a new one.
If the current buffer is a browser window, and there are other,
prompt the user for a new one to select, and switch to that
buffer.

With prefix argument ARG, always create a new browser window."
  (interactive "P")
  ;; If called with prefix, just create a new window
  (if arg (browser-tab-switcher-new-window)
    ;; When there are no browser window and when the current one is the only one,
    ;; we want to create a new one. We eliminate from the list of all the buffers
    ;; the current one, if there are zero browser window it means that we have to
    ;; create a new one (this happens if there are no browser window or if the
    ;; current one is the only one).
    (let* ((browser-windows (browser-tab-switcher--get-browser-windows))
           (browser-window-names (mapcar #'buffer-name browser-windows))
           (browser-window-names-without-prefix
            (mapcar
             (lambda (name)
               (string-remove-prefix
                (concat browser-tab-switcher-buffer-name-prefix " ") name))
             browser-window-names))
           (num-browser-windows (length browser-windows)))
      (if (eq num-browser-windows 0)
          (browser-tab-switcher-new-window)
        (browser-tab-switcher--create-or-switch
         browser-window-names-without-prefix)))))

(provide 'browser-tab-switcher)

;;; browser-tab-switcher.el ends here
