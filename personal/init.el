(prelude-require-packages
 '(
   clang-format
   solarized-theme
   intero
   irony
   company-irony
   company-irony-c-headers
   irony-eldoc
   flycheck-irony
   neotree
   goto-chg
   rtags))

(add-to-list 'load-path "~/.emacs.d/rtags/build/src")

(require 'prelude-haskell)
(require 'projectile)

(projectile-global-mode)
(add-hook 'c-mode-hook 'projectile-mode)
(add-hook 'c++-mode-hook 'projectile-mode)

(add-hook 'haskell-mode-hook 'intero-mode)

(setq inhibit-startup-message t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(irony-cdb-search-directory-list
   (quote
    ("build/BourneoDB/Clang/Debug" "build/BourneoDB/Clang/Release"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "unknown" :slant normal :weight normal :height 132 :width normal)))))

;;(tool-bar-mode -1)
;;(scroll-bar-mode -1)
;;(menu-bar-mode -1)
;;(define-key emacs-lisp-mode-map (kbd "M-.") 'find-function-at-point)
;;(setenv "PAGER" "/bin/cat")
(ido-mode 1)
(show-paren-mode 1)
(eldoc-mode 1)

(require 'uniquify)

(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)

(defun my-irony-mode-hook ()
  (define-key irony-mode-map [remap completion-at-point]
    'irony-completion-at-point-async)
  (define-key irony-mode-map [remap complete-symbol]
    'irony-completion-at-point-async))

(add-hook 'irony-mode-hook 'my-irony-mode-hook)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

(eval-after-load 'company
  '(add-to-list
     'company-backends '(company-irony-c-headers company-irony)))

(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c-mode-hook 'company-mode)

(add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)

(add-hook 'c++-mode-hook 'flycheck-mode)
(add-hook 'c-mode-hook 'flycheck-mode)
(eval-after-load 'flycheck
  '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))

(require 'company-irony-c-headers)
;; Load with `irony-mode` as a grouped backend
(eval-after-load 'company
  '(add-to-list
    'company-backends '(company-irony-c-headers company-irony)))

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

(setq company-idle-delay 0)
;;(define-key c-mode-map [(tab)] 'company-complete)
(add-hook 'c-mode-common-hook
          (lambda () (define-key c++-mode-map [(tab)] 'company-complete)))
(add-hook 'irony-mode-hook 'irony-eldoc)

;; ==========================================
;; (optional) bind TAB for indent-or-complete
;; ==========================================
(defun irony--check-expansion ()
(save-excursion
  (if (looking-at "\\_>") t
    (backward-char 1)
    (if (looking-at "\\.") t
      (backward-char 1)
      (if (looking-at "->") t nil)))))
(defun irony--indent-or-complete ()
"Indent or Complete"
(interactive)
(cond ((and (not (use-region-p))
            (irony--check-expansion))
       (message "complete")
       (company-complete-common))
      (t
       (message "indent")
       (call-interactively 'c-indent-line-or-region))))
(defun irony-mode-keys ()
"Modify keymaps used by `irony-mode'."
(local-set-key (kbd "TAB") 'irony--indent-or-complete)
(local-set-key [tab] 'irony--indent-or-complete))
(add-hook 'c-mode-common-hook 'irony-mode-keys)



(defun build-clang-debug ()
  "Run the closest build command."
  (interactive)
  (build-with-args "build --compiler Clang --variant Debug"))

(defun build-clang-release ()
  "Run the closest build command."
  (interactive)
  (build-with-args "build --compiler Clang --variant Release"))

(defun build-gcc-debug ()
  "Run the closest build command."
  (interactive)
  (build-with-args "build --compiler Gcc --variant Debug"))

(defun build ()
  "Run the closest build command."
  (interactive)
  (build-gcc-release))

(defun build-gcc-release ()
  "Run the closest build command."
  (interactive)
  (build-with-args "build --compiler Gcc --variant Release"))

(defun build-all ()
  "Run the closest build command."
  (interactive)
  (build-with-args "all"))

(defun build-static-analyser ()
  "Run the closest build command."
  (interactive)
  (build-with-args "staticanalyse"))

(defun build-clean ()
  "Run the closest build command."
  (interactive)
  (build-with-args "clean"))

(defun build-with-args (&optional args)
  (save-some-buffers 1)
  (setq build-command "build.sh")
  (setq dirname (upward-find-file build-command "."))
  (setq arg-list (if args (concat " " args) ""))

                                        ; We've now worked out where to start. Now we need to worry about
                                        ; calling compile in the right directory
  (when dirname (save-excursion
                  (setq dir-buffer (find-file-noselect dirname))
                  (set-buffer dir-buffer)
                  (compile (concat (file-name-as-directory dirname) build-command arg-list))
                  (kill-buffer dir-buffer))))

(defun upward-find-file (filename startdir)
  "Move up directories until we find a certain filename. If we
  manage to find it, return the containing directory. Else if we
  get to the toplevel directory and still can't find it, return
  nil. Start at startdir or . if startdir not given"

  (let ((dirname (expand-file-name startdir))
        (found nil) ; found is set as a flag to leave loop if we find it
        (top nil))  ; top is set when we get to / so that we only check it once

    ; While we've neither been at the top last time nor have we found
    ; the file.
    (while (not (or found top))
      ; If we're at / set top flag.
      (if (string= (expand-file-name dirname) "/")
          (setq top t))

      ; Check for the file
      (if (file-exists-p (expand-file-name filename dirname))
          (setq found t)
        (setq dirname (expand-file-name ".." dirname)))) ; If not, move up a directory
    ; return statement
    (if found dirname nil)))

(defun sjb-remote-mode ()
  (interactive)
  (setq interprogram-cut-function nil))

(require 'neotree)
(require 'projectile)

(global-set-key [f8] 'neotree-toggle)
(global-set-key [f9] 'neotree-projectile-action)
(setq neo-smart-open t)
(setq projectile-switch-project-action 'neotree-projectile-action)

;; Indentation style
(setq-default c-basic-offset 4)

(defun followed-by (cases)
  (cond ((null cases) nil)
        ((assq (car cases)
               (cdr (memq c-syntactic-element c-syntactic-context))) t)
        (t (followed-by (cdr cases)))))

(c-add-style  "simon"
              `(( other . personalizations )
        (c-offsets-alist
         (innamespace
          . (lambda (x)
          (if (followed-by
               '(innamespace namespace-close)) 0 '+))))))

(setq c-default-style "simon"
          c-basic-offset 4)

(require 'rtags)
(require 'company-rtags)

;;(setq rtags-completions-enabled t)
;;(eval-after-load 'company
  ;;'(add-to-list
    ;;'company-backends 'company-rtags))
(setq rtags-autostart-diagnostics t)

(define-key c-mode-base-map (kbd "M-.") (function rtags-find-symbol-at-point))
(define-key c-mode-base-map (kbd "M-,") (function rtags-find-references-at-point))
;;(define-key c-mode-base-map (kbd "M-;") (function tags-find-file))
(define-key c-mode-base-map (kbd "C-.") (function rtags-find-symbol))
(define-key c-mode-base-map (kbd "C-,") (function rtags-find-references))
(define-key c-mode-base-map (kbd "C-<") (function rtags-find-virtuals-at-point))
(define-key c-mode-base-map (kbd "M-i") (function rtags-imenu))

(add-hook 'c-mode-common-hook 'rtags-start-process-unless-running)
(add-hook 'c++-mode-common-hook 'rtags-start-process-unless-running)

(setq compilation-scroll-output t)

(require 'clang-format)
(define-key c-mode-base-map (kbd "<C-S-tab>") (function clang-format-region))
(define-key c-mode-base-map (kbd "<C-tab>") (function clang-format-buffer))

(setq prelude-flyspell nil)
(setq prelude-guru nil)

;; Disable smartparens keys
(require 'smartparens)
(custom-set-variables
 '(sp-override-key-bindings (quote (("C-<right>") ("C-<left>")))))

(require 'misc)
(global-set-key [C-right] 'forward-to-word)

;; Kill words
(global-set-key [C-backspace] 'backward-kill-word)
(global-set-key [C-delete] 'kill-word)

;; Kill to start/end of line
(global-set-key [M-backspace] (lambda nil (interactive) (kill-line 0)))
(global-set-key [M-delete] 'kill-line)

;; Window moving
(global-set-key [M-left] 'windmove-left)
(global-set-key [M-right] 'windmove-right)
(global-set-key [M-up] 'windmove-up)
(global-set-key [M-down] 'windmove-down)

;; Unset crazy prelude keybindings for window moving
(global-unset-key [S-left])
(global-unset-key [S-right])
(global-unset-key [S-up])
(global-unset-key [S-down])

;; Undo navigation
(require 'goto-chg)
(global-set-key [S-M-left] 'goto-last-change)
(global-set-key [S-M-right] 'goto-last-change-reverse)
