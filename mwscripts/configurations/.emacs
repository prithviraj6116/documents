(add-to-list 'load-path "//mathworks/devel/sandbox/ppatil/configurations/.emacs.d")

(split-window-right)

(global-set-key "\M-\C-c" `scroll-other-window-down)

(defun mydired-openinnewwindow_previous ()
  "ext-lie "
  (interactive)
  (dired-previous-line 1)
  (dired-display-file))

(defun mydired-openinnewwindow_next ()
  "next "
  (interactive)
  (dired-next-line 1);current-prefix-arg)
  (dired-display-file))

(add-hook 'dired-load-hook ;; guessing
    '(lambda ()
       (global-set-key "\M-n" 'mydired-openinnewwindow_next)))
(add-hook 'dired-load-hook ;; guessing
    '(lambda ()
       (global-set-key "\M-p" 'mydired-openinnewwindow_previous)))
(toggle-frame-maximized)


(require 'redo)
(global-set-key [(control +)] 'redo)

(fset 'yes-or-no-p 'y-or-n-p)

(setq inhibit-startup-message t)


;;(add-to-list 'default-frame-alist '(foreground-color . "#E0DFDB"))
;;(add-to-list 'default-frame-alist '(background-color . "black"));;#102372"))
(load-file "//mathworks/hub/share/sbtools/emacs_setup.el")


(global-linum-mode)
