;;; packages.el --- Java functions File for Spacemacs
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Lukasz Klich <klich.lukasz@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defun spacemacs//java-define-command-prefixes ()
  "Define command prefixes for java-mode."
  (setq java/key-binding-prefixes '(("me" . "errors")
                                    ("md" . "eclimd")
                                    ("mf" . "find")
                                    ("mg" . "goto")
                                    ("mr" . "refactor")
                                    ("mh" . "documentation")
                                    ("mm" . "maven")
                                    ("ma" . "ant")
                                    ("mp" . "project")
                                    ("mt" . "test")))
  (mapc (lambda(x) (spacemacs/declare-prefix-for-mode
                    'java-mode (car x) (cdr x)))
        java/key-binding-prefixes))

(defun spacemacs//java-setup-backend ()
  "Conditionally setup java backend."
  (pcase java-backend
    (`eclim (spacemacs//java-setup-eclim))
    (`ensime (spacemacs//java-setup-ensime))
    (`meghanada (spacemacs//java-setup-meghanada))))

(defun spacemacs//java-setup-company ()
  "Conditionally setup company based on backend."
  (pcase java-backend
    (`eclim (spacemacs//java-setup-eclim-company))
    (`ensime (spacemacs//java-setup-ensime-company))
    (`meghanada (spacemacs//java-setup-meghanada-company))))

(defun spacemacs//java-setup-flycheck ()
  "Conditionally setup flycheck based on backend."
  (pcase java-backend
    (`ensime (spacemacs//java-setup-ensime-flycheck))
    (`meghanada (spacemacs//java-setup-meghanada-flycheck))))

(defun spacemacs//java-setup-flyspell ()
  "Conditionally setup flyspell based on backend."
  (pcase java-backend
    (`ensime (spacemacs//java-setup-ensime-flyspell))
    (`meghanada (spacemacs//java-setup-meghanada-flyspell))))

(defun spacemacs//java-setup-eldoc ()
  "Conditionally setup eldoc based on backend."
  (pcase java-backend
    (`ensime (spacemacs//java-setup-ensime-eldoc))
    (`meghanada (spacemacs//java-setup-meghanada-eldoc))))



;; ensime

(autoload 'ensime-config-find-file "ensime-config")
(autoload 'ensime-config-find "ensime-config")
(autoload 'projectile-project-p "projectile")

(defun spacemacs//java-setup-ensime ()
  "Setup ENSIME."
  ;; jump handler
  (add-to-list 'spacemacs-jump-handlers 'ensime-edit-definition)
  ;; ensure the file exists before starting `ensime-mode'
  (cond
   ((and (buffer-file-name) (file-exists-p (buffer-file-name)))
    (ensime-mode))
   ((buffer-file-name)
    (add-hook 'after-save-hook 'ensime-mode nil t))))

(defun spacemacs//java-setup-ensime-company ()
  "Setup ENSIME auto-completion.")

(defun spacemacs//java-setup-ensime-flycheck ()
  "Setup ENSIME syntax checking.")

(defun spacemacs//java-setup-ensime-flyspell ()
  "Setup ENSIME spell checking."
  (flyspell-mode)
  (setq-local flyspell-generic-check-word-predicate
              'spacemacs//ensime-flyspell-verify))

(defun spacemacs//java-setup-ensime-eldoc ()
  "Setup ENSIME eldoc."
  (setq-local eldoc-documentation-function
              (lambda ()
                (when (ensime-connected-p)
                  (ensime-print-type-at-point))))
  (eldoc-mode))

(defun spacemacs//ensime-maybe-start ()
  (when (buffer-file-name)
    (let ((ensime-buffer (spacemacs//ensime-buffer-for-file (buffer-file-name)))
          (file (ensime-config-find-file (buffer-file-name)))
          (is-source-file (s-matches? (rx (or "/src/" "/test/"))
                                      (buffer-file-name))))

      (when (and is-source-file (null ensime-buffer))
        (noflet ((ensime-config-find (&rest _) file))
          (save-window-excursion
            (ensime)))))))

(defun spacemacs//ensime-buffer-for-file (file)
  "Find the Ensime server buffer corresponding to FILE."
  (let ((default-directory (file-name-directory file)))
    (-when-let (project-name (projectile-project-p))
      (--first (-when-let (bufname (buffer-name it))
                 (and (s-contains? "inferior-ensime-server" bufname)
                      (s-contains? (file-name-nondirectory project-name)
                                   bufname)))
               (buffer-list)))))

(defun spacemacs//ensime-flyspell-verify ()
  "Prevent common flyspell false positives in scala-mode."
  (and (flyspell-generic-progmode-verify)
       (not (s-matches? (rx bol (* space) "package") (current-line)))))

;; key bindings

(defun spacemacs/ensime-configure-keybindings (mode)
  "Define Ensime key bindings for MODE."
  (dolist (prefix '(("mb" . "build")
                    ("mc" . "check")
                    ("md" . "debug")
                    ("me" . "errors")
                    ("mg" . "goto")
                    ("mh" . "docs")
                    ("mi" . "inspect")
                    ("mn" . "ensime")
                    ("mr" . "refactor")
                    ("mt" . "test")
                    ("ms" . "repl")
                    ("my" . "yank")))
    (spacemacs/declare-prefix-for-mode mode (car prefix) (cdr prefix)))

  (spacemacs/set-leader-keys-for-major-mode mode
    "/"      'ensime-search
    "'"      'ensime-inf-switch

    "bc"     'ensime-sbt-do-compile
    "bC"     'ensime-sbt-do-clean
    "bi"     'ensime-sbt-switch
    "bp"     'ensime-sbt-do-package
    "br"     'ensime-sbt-do-run

    "ct"     'ensime-typecheck-current-buffer
    "cT"     'ensime-typecheck-all

    "dA"     'ensime-db-attach
    "db"     'ensime-db-set-break
    "dB"     'ensime-db-clear-break
    "dC"     'ensime-db-clear-all-breaks
    "dc"     'ensime-db-continue
    "di"     'ensime-db-inspect-value-at-point
    "dn"     'ensime-db-next
    "do"     'ensime-db-step-out
    "dq"     'ensime-db-quit
    "dr"     'ensime-db-run
    "ds"     'ensime-db-step
    "dt"     'ensime-db-backtrace

    "ee"     'ensime-print-errors-at-point
    "el"     'ensime-show-all-errors-and-warnings
    "es"     'ensime-stacktrace-switch

    "gp"     'ensime-pop-find-definition-stack
    "gi"     'ensime-goto-impl
    "gt"     'ensime-goto-test

    "hh"     'ensime-show-doc-for-symbol-at-point
    "hT"     'ensime-type-at-point-full-name
    "ht"     'ensime-type-at-point
    "hu"     'ensime-show-uses-of-symbol-at-point

    "ii"     'ensime-inspect-type-at-point
    "iI"     'ensime-inspect-type-at-point-other-frame
    "ip"     'ensime-inspect-project-package

    "nF"     'ensime-reload-open-files
    "ns"     'ensime
    "nS"     'spacemacs/ensime-gen-and-restart

    "ra"     'ensime-refactor-add-type-annotation
    "rd"     'ensime-refactor-diff-inline-local
    "rD"     'ensime-undo-peek
    "rf"     'ensime-format-source
    "ri"     'ensime-refactor-diff-organize-imports
    "rm"     'ensime-refactor-diff-extract-method
    "rr"     'ensime-refactor-diff-rename
    "rt"     'ensime-import-type-at-point
    "rv"     'ensime-refactor-diff-extract-local

    "ta"     'ensime-sbt-do-test-dwim
    "tr"     'ensime-sbt-do-test-quick-dwim
    "tt"     'ensime-sbt-do-test-only-dwim

    "sa"     'ensime-inf-load-file
    "sb"     'ensime-inf-eval-buffer
    "sB"     'spacemacs/ensime-inf-eval-buffer-switch
    "si"     'ensime-inf-switch
    "sr"     'ensime-inf-eval-region
    "sR"     'spacemacs/ensime-inf-eval-region-switch

    "yT"     'spacemacs/ensime-yank-type-at-point-full-name
    "yt"     'spacemacs/ensime-yank-type-at-point

    "z"      'ensime-expand-selection-command))

;; interactive functions

(defun spacemacs/ensime-gen-and-restart()
  "Regenerate `.ensime' file and restart the ensime server."
  (interactive)
  (progn
    (sbt-command ";ensimeConfig;ensimeConfigProject")
    (ensime-shutdown)
    (ensime)))

(defun spacemacs/ensime-inf-eval-buffer-switch ()
  "Send buffer content to shell and switch to it in insert mode."
  (interactive)
  (ensime-inf-eval-buffer)
  (ensime-inf-switch)
  (evil-insert-state))

(defun spacemacs/ensime-inf-eval-region-switch (start end)
  "Send region content to shell and switch to it in insert mode."
  (interactive "r")
  (ensime-inf-switch)
  (ensime-inf-eval-region start end)
  (evil-insert-state))

(defun spacemacs/ensime-refactor-accept ()
  (interactive)
  (funcall continue-refactor)
  (ensime-popup-buffer-quit-function))

(defun spacemacs/ensime-refactor-cancel ()
  (interactive)
  (funcall cancel-refactor)
  (ensime-popup-buffer-quit-function))

(defun spacemacs/ensime-completing-dot ()
  "Insert a period and show company completions."
  (interactive "*")
  (when (s-matches? (rx (+ (not space)))
                    (buffer-substring (line-beginning-position) (point)))
    (delete-horizontal-space t))
  (company-abort)
  (insert ".")
  (company-complete))

(defun spacemacs/ensime-yank-type-at-point ()
  "Yank to kill ring and print short type name at point to the minibuffer."
  (interactive)
  (ensime-type-at-point t nil))

(defun spacemacs/ensime-yank-type-at-point-full-name ()
  "Yank to kill ring and print full type name at point to the minibuffer."
  (interactive)
  (ensime-type-at-point t t))


;; eclim

(defun spacemacs//java-setup-eclim ()
  "Setup Eclim."
  ;; jump handler
  (add-to-list 'spacemacs-jump-handlers 'eclim-java-find-declaration)
  ;; enable eclim
  (eclim-mode))

(defun spacemacs//java-setup-eclim-company ()
  "Setup Eclim auto-completion."
  (spacemacs|add-company-backends
    :backends company-emacs-eclim
    :modes eclim-mode
    :hooks nil)
  ;; call manualy generated functions by the macro
  (spacemacs//init-company-eclim-mode)
  (company-mode))

(defun spacemacs/java-eclim-completing-dot ()
  "Insert a period and show company completions."
  (interactive "*")
  (spacemacs//java-delete-horizontal-space)
  (insert ".")
  (company-emacs-eclim 'interactive))

(defun spacemacs/java-eclim-completing-double-colon ()
  "Insert double colon and show company completions."
  (interactive "*")
  (spacemacs//java-delete-horizontal-space)
  (insert ":")
  (let ((curr (point)))
    (when (s-matches? (buffer-substring (- curr 2) (- curr 1)) ":")
      (company-emacs-eclim 'interactive))))


;; meghanada

(defun spacemacs//java-setup-meghanada ()
  "Setup Meghanada."
  (require 'meghanada)
  ;; jump handler
  (add-to-list 'spacemacs-jump-handlers
               '(meghanada-jump-declaration
                 :async spacemacs//java-meghanada-server-livep))
  ;; auto-install meghanada server
  (let ((dest-jar (meghanada--locate-server-jar)))
    (unless dest-jar
      (meghanada-install-server)))
  ;; enable meghanada
  (meghanada-mode))

(defun spacemacs//java-setup-meghanada-company ()
  "Setup Meghanada auto-completion."
  (meghanada-company-enable))

(defun spacemacs//java-setup-meghanada-flycheck ()
  "Setup Meghanada syntax checking."
  (spacemacs/add-flycheck-hook 'java-mode)
  (require 'flycheck-meghanada)
  (add-to-list 'flycheck-checkers 'meghanada)
  (flycheck-mode))

(defun spacemacs//java-setup-meghanada-flyspell ()
  "Setup Meghanada spell checking.")

(defun spacemacs//java-setup-meghanada-eldoc ()
  "Setup Meghanada eldoc.")

(defun spacemacs//java-meghanada-server-livep ()
  "Return non-nil if the Meghanada server is up."
  (and meghanada--client-process (process-live-p meghanada--client-process)))


;; Maven

(defun spacemacs/java-maven-test ()
  (interactive)
  (eclim-maven-run "test"))

(defun spacemacs/java-maven-clean-install ()
  (interactive)
  (eclim-maven-run "clean install"))

(defun spacemacs/java-maven-install ()
  (interactive)
  (eclim-maven-run "install"))


;; Misc

(defun spacemacs//java-delete-horizontal-space ()
  (when (s-matches? (rx (+ (not space)))
                    (buffer-substring (line-beginning-position) (point)))
    (delete-horizontal-space t)))
