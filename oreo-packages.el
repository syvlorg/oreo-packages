;;; oreo-packages.el --- functions to manage system packages -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2021 Free Software Foundation, Inc.

;; Author: J. Alexander Branham <alex.branham@gmail.com>
;; Maintainer: J. Alexander Branham <alex.branham@gmail.com>
;; URL: https://github.com/syvlorg/oreo-packages
;; Package-Requires: ((emacs "24.3"))
;; Version: 1.0.11

;; This file is part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>

;;; Commentary:

;; This is a package to manage installed system packages.  Useful
;; functions include installing packages, removing packages, listing
;; installed packages, and others.

;; Helm users might also be interested in helm-oreo-packages.el
;; <https://github.com/emacs-helm/helm-oreo-packages>

;; Usage:

;; (require 'oreo-packages)
;;

;;; Code:
(defgroup oreo-packages nil
  "Manages system packages"
  :tag "Oreo Packages"
  :prefix "oreo-packages"
  :group 'packages)

(defvar oreo-packages-supported-package-managers
  '(
    ;; guix
    (guix .
          ((default-sudo . nil)
           (install . "guix package -i")
           (search . "guix package -s")
           (uninstall . "guix package -r")
           (update . "guix package --upgrade")
           (clean-cache . "guix gc")
           (log . nil)
           (get-info . nil)
           (get-info-remote . nil)
           (list-files-provided-by . nil)
           (verify-all-packages . nil)
           (verify-all-dependencies . nil)
           (remove-orphaned . nil)
           (list-installed-packages . "guix package -I")
           (list-installed-packages-all . "guix package -I")
           (list-dependencies-of . nil)
           (noconfirm . nil)))
    ;; nix
    (nix .
         ((default-sudo . nil)
          (install . "nix-env -i")
          (search . "nix search")
          (uninstall . "nix-env -e")
          (update . "nix-env -u")
          (clean-cache . "nix-collect-garbage")
          (log . nil)
          (get-info . nil)
          (get-info-remote . nil)
          (list-files-provided-by . nil)
          (verify-all-packages . nil)
          (verify-all-dependencies . nil)
          (remove-orphaned . nil)
          (list-installed-packages . "nix-env -q")
          (list-installed-packages-all . "nix-env -q")
          (list-dependencies-of . nil)
          (noconfirm . nil)))
    ;; Mac
    (brew .
          ((default-sudo . nil)
           (install . "brew install")
           (search . "brew search")
           (uninstall . "brew uninstall")
           (update . "brew update && brew upgrade")
           (clean-cache . "brew cleanup")
           (log . nil)
           (get-info . nil)
           (get-info-remote . nil)
           (list-files-provided-by . "brew ls --verbose")
           (verify-all-packages . nil)
           (verify-all-dependencies . nil)
           (remove-orphaned . nil)
           (list-installed-packages . "brew list")
           (list-installed-packages-all . "brew list")
           (list-dependencies-of . "brew deps")
           (noconfirm . nil)))
    (port .
          ((default-sudo . t)
           (install . "port install")
           (search . "port search")
           (uninstall . "port uninstall")
           (update . "port sync && port upgrade outdated")
           (clean-cache . "port clean --all")
           (log . "port log")
           (get-info . "port info")
           (get-info-remote . nil)
           (list-files-provided-by . "port contents")
           (verify-all-packages . nil)
           (verify-all-dependencies . nil)
           (remove-orphaned . "port uninstall leaves")
           (list-installed-packages . "port installed")
           (list-installed-packages-all . "port installed")
           (list-dependencies-of . "port deps")
           (noconfirm . nil)))
    ;; Arch-based systems
    (pacman .
            ((default-sudo . t)
             (install . "pacman -S")
             (search . "pacman -Ss")
             (uninstall . "pacman -Rns")
             (update . "pacman -Syu")
             (clean-cache . "pacman -Sc")
             (change-log . "pacman -Qc")
             (log . "cat /var/log/pacman.log")
             (get-info . "pacman -Qi")
             (get-info-remote . "pacman -Si")
             (list-files-provided-by . "pacman -qQl")
             (owning-file . "pacman -Qo")
             (owning-file-remote . "pacman -F")
             (verify-all-packages . "pacman -Qkk")
             (verify-all-dependencies . "pacman -Dk")
             (remove-orphaned . "pacman -Rns $(pacman -Qtdq)")
             (list-installed-packages . "pacman -Qe")
             (list-installed-packages-all . "pacman -Q")
             (list-dependencies-of . "pacman -Qi")
             (noconfirm . "--noconfirm")))
    ;; Debian (and Ubuntu) based systems
    (apt .
         ((default-sudo . t)
          (install . "apt-get install")
          (search . "apt-cache search")
          (uninstall . "apt-get --purge remove")
          (update . "apt-get update && apt-get upgrade")
          (clean-cache . "apt-get clean")
          (log . "cat /var/log/dpkg.log")
          (change-log . "apt-get changelog")
          (get-info . "dpkg -s")
          (get-info-remote . "apt-cache show")
          (list-files-provided-by . "dpkg -L")
          (owning-file . "dpkg -S")
          (owning-file-remote . "apt-file search")
          (verify-all-packages . "debsums")
          (verify-all-dependencies . "apt-get check")
          (remove-orphaned . "apt-get autoremove")
          (list-installed-packages . "dpkg -l")
          (list-installed-packages-all . "dpkg -l")
          (list-dependencies-of . "apt-cache depends")
          (noconfirm . "-y")))
    (aptitude .
              ((default-sudo . t)
               (install . "aptitude install")
               (search . "aptitude search")
               (uninstall . "aptitude remove")
               (update . "apt update && aptitude safe-upgrade")
               (clean-cache . "aptitude clean")
               (log . "cat /var/log/dpkg.log")
               (change-log . "aptitude changelog")
               (get-info . "aptitude show")
               (get-info-remote . "aptitude show")
               (list-files-provided-by . "dpkg -L")
               (owning-file . "dpkg -S")
               (owning-file-remote . "apt-file search")
               (verify-all-packages . "debsums")
               (verify-all-dependencies . "apt-get check")
               (remove-orphaned . nil) ; aptitude does this automatically
               (list-installed-packages . "aptitude search '~i!~M'")
               (list-installed-packages-all . "aptitude search '~i!~M'")
               (list-dependencies-of . "apt-cache deps")
               (noconfirm . "-y")))
    ;; Gentoo
    (emerge .
            ((default-sudo . t)
             (install . "emerge")
             (search . "emerge -S")
             (uninstall . "emerge -C")
             (update . "emerge -u world")
             (clean-cache . "eclean distfiles")
             (log . "cat /var/log/portage")
             (change-log . "equery changes -f")
             (get-info . "emerge -pv")
             (get-info-remote . "emerge -S")
             (list-files-provided-by . "equery files")
             (owning-file . "equery belongs")
             (owning-file-remote . "equery belongs")
             (verify-all-packages . "equery check")
             (verify-all-dependencies . "emerge -uDN world")
             (remove-orphaned . "emerge --depclean")
             (list-installed-packages . nil)
             (list-installed-packages-all . nil)
             (list-dependencies-of . "emerge -ep")
             (noconfirm . nil)))
    ;; openSUSE
    (zypper .
            ((default-sudo . t)
             (install . "zypper install")
             (search . "zypper search")
             (uninstall . "zypper remove")
             (update . "zypper update")
             (clean-cache . "zypper clean")
             (log . "cat /var/log/zypp/history")
             (get-info . "zypper info")
             (get-info-remote . "zypper info")
             (list-files-provided-by . "rpm -Ql")
             (owning-file . "zypper search -f")
             (owning-file-remote . "zypper search -f")
             (verify-all-packages . "rpm -Va")
             (verify-all-dependencies . "zypper verify")
             (remove-orphaned . "zypper rm -u")
             (list-installed-packages . nil)
             (list-installed-packages-all . nil)
             (list-dependencies-of . "zypper info --requires")
             (noconfirm . nil)))
    ;; Fedora
    (dnf .
         ((default-sudo . t)
          (install . "dnf install")
          (search . "dnf search")
          (uninstall . "dnf remove")
          (update . "dnf upgrade")
          (clean-cache . "dnf clean all")
          (change-log . "rpm -q --changelog")
          (log . "dnf history")
          (get-info . "rpm -qi")
          (get-info-remote . "dnf info")
          (list-files-provided-by . "rpm -ql")
          (owning-file . "rpm -qf")
          (owning-file-remote . "dnf provides")
          (verify-all-packages . "rpm -Va")
          (verify-all-dependencies . "dnf repoquery --requires")
          (remove-orphaned . "dnf autoremove")
          (list-installed-packages . "dnf list --installed")
          (list-installed-packages-all . nil)
          (list-dependencies-of . "rpm -qR")
          (noconfirm . nil)))
    ;; RedHat derivatives
    (yum .
	 ((default-sudo . t)
	  (install . "yum install")
	  (search . "yum search")
	  (uninstall . "yum remove")
	  (update . "yum update")
	  (clean-cache . "yum clean expire-cache")
	  (log . "cat /var/log/yum.log")
          (change-log . "rpm -q --changelog")
	  (get-info . "yum info")
	  (get-info-remote . "repoquery --plugins -i")
	  (list-files-provided-by . "rpm -ql")
          (owning-file . "rpm -qf")
          (owning-file-remote . "repoquery -f")
	  (verify-all-packages)
	  (verify-all-dependencies)
	  (remove-orphaned . "yum autoremove")
	  (list-installed-packages . "yum list installed")
	  (list-installed-packages-all . "yum list installed")
	  (list-dependencies-of . "yum deplist")
	  (noconfirm . "-y")))
    ;; Void
    ;; xbps is the name of the package manager, but that doesn't appear as an
    ;; executable, so let's just call it xbps-install:
    (xbps-install .
                  ((default-sudo . t)
                   (install . "xbps-install")
                   (search . "xbps-query -Rs")
                   (uninstall . "xbps-remove -R")
                   (update . "xbps-install -Su")
                   (clean-cache . "xbps-remove -O")
                   (log . nil)
                   (get-info . "xbps-query")
                   (get-info-remote . "xbps-query -R")
                   (list-files-provided-by . "xbps-query -f")
                   (verify-all-packages . nil)
                   (verify-all-dependencies . "xbps-pkgdb -a")
                   (remove-orphaned . "dnf autoremove")
                   (list-installed-packages . "xbps-query -l ")
                   (list-installed-packages-all . "xbps-query -l ")
                   (list-dependencies-of . "xbps-query -x")
                   (noconfirm . nil))))
  "An alist of package manager commands.
The key is the package manager and value (usually) the shell command to run.
Any occurrences of ~%p~ in the command will be replaced with the package
name during execution, otherwise the package name is simply appended
to the command.")
(put 'oreo-packages-supported-package-managers 'risky-local-variable t)

(define-obsolete-variable-alias 'oreo-packages-packagemanager
  'oreo-packages-package-manager "2017-12-25")
(defcustom oreo-packages-package-manager
  (let ((managers oreo-packages-supported-package-managers)
        manager)
    (while managers
      (progn
        (setq manager (pop managers))
        (if (executable-find (symbol-name (car manager)))
            (setq managers nil)
          (setq manager nil))))
    (car manager))
  "Symbol naming the package manager to use.
See `oreo-packages-supported-package-managers' for the list of
supported software.  Tries to be smart about selecting the
default.  If you change this value, you may also want to change
`oreo-packages-use-sudo'."
  :type '(choice
          (const guix)
          (const nix-env)
          (const brew)
          (const port)
          (const pacman)
          (const apt)
          (const aptitude)
          (const emerge)
          (const zypper)
          (const dnf)
          (const xbps-install)))

(define-obsolete-variable-alias 'oreo-packages-usesudo
  'oreo-packages-use-sudo "2017-12-25")
(defcustom oreo-packages-use-sudo
  (cdr (assoc 'default-sudo (cdr (assoc oreo-packages-package-manager
                                        oreo-packages-supported-package-managers))))
  "If non-nil, oreo-packages uses sudo for appropriate commands.

Tries to be smart for selecting the default."
  :type 'boolean)

(defcustom oreo-packages-noconfirm nil
  "If non-nil, bypass prompts asking the user to confirm package upgrades."
  :type 'boolean)

(defun oreo-packages-get-command (action &optional pack args)
  "Return a command to run as a string.
ACTION should be in
`oreo-packages-supported-package-managers' (e.g. 'install).
PACK is used to operate on a specific package, and ARGS is a way
of passing additional arguments to the package manager."
  (let ((command
         (cdr (assoc action (cdr (assoc oreo-packages-package-manager
                                        oreo-packages-supported-package-managers)))))
        (noconfirm (when oreo-packages-noconfirm
                     (cdr (assoc 'noconfirm
                                 (cdr (assoc oreo-packages-package-manager
                                             oreo-packages-supported-package-managers)))))))
    (unless command
      (error (format "%S not supported in %S" action oreo-packages-package-manager)))
    (setq command
          (if (string-match-p "%p" command)
              (replace-regexp-in-string "%p" pack command t t)
            (concat command " " pack)))
    (when noconfirm
      (setq args (concat args (and pack " ") noconfirm)))
    (concat command args)))

(defun oreo-packages--run-command (action &optional pack args)
  "Run a command asynchronously using the system's package manager.
See `oreo-packages-get-command' for how to use ACTION, PACK,
and ARGS."
  (let ((command (oreo-packages-get-command action pack args))
        (default-directory (if oreo-packages-use-sudo
                               "/sudo::"
                             default-directory))
        (inhibit-read-only t))
    (async-shell-command command "*oreo-packages*")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions on named packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun oreo-packages-install (pack &optional args)
  "Install system packages.

Use the package manager from `oreo-packages-package-manager' to
install PACK.  You may use ARGS to pass options to the package
manger."
  (interactive "sPackage to install: ")
  (oreo-packages--run-command 'install pack args))

;;;###autoload
(defun oreo-packages-ensure (pack &optional args)
  "Ensure PACK is installed on system.
Search for PACK with `oreo-packages-package-installed-p', and
install the package if not found.  Use ARGS to pass options to
the package manager."
  (interactive "sPackage to ensure is present: ")
  (if (oreo-packages-package-installed-p pack)
      t
    (oreo-packages-install pack args)))

;;;###autoload
(defalias 'oreo-packages-package-installed-p #'executable-find
  "Return t if PACK is installed.
Currently an alias for `executable-find', so it will give wrong
results if the package and executable names are different.")

;;;###autoload
(defun oreo-packages-search (pack &optional args)
  "Search for system packages.

Use the package manager named in `oreo-packages-package-manager'
to search for PACK.  You may use ARGS to pass options to the
package manager."
  (interactive "sSearch string: ")
  (oreo-packages--run-command 'search pack args))

;;;###autoload
(defun oreo-packages-uninstall (pack &optional args)
  "Uninstall system packages.

Uses the package manager named in
`oreo-packages-package-manager' to uninstall PACK.  You may use
ARGS to pass options to the package manager."
  (interactive "sPackage to uninstall: ")
  (oreo-packages--run-command 'uninstall pack args))

;;;###autoload
(defun oreo-packages-list-dependencies-of (pack &optional args)
  "List the dependencies of PACK.

You may use ARGS to pass options to the package manager."
  (interactive "sPackage to list dependencies of: ")
  (oreo-packages--run-command 'list-dependencies-of pack args))

;;;###autoload
(defun oreo-packages-get-info (pack &optional args)
  "Display local package information of PACK.

With a prefix argument, display remote package information.  You
may use ARGS to pass options to the package manager."
  (interactive "sPackage to list info for: ")
  (if current-prefix-arg
      (oreo-packages--run-command 'get-info-remote pack args)
    (oreo-packages--run-command 'get-info pack args)))

;;;###autoload
(defun oreo-packages-list-files-provided-by (pack &optional args)
  "List the files provided by PACK.

You may use ARGS to pass options to the package manager."
  (interactive "sPackage to list provided files of: ")
  (oreo-packages--run-command 'list-files-provided-by pack args))

;;;###autoload
(defun oreo-packages-owning-file (file &optional args)
  "Search for packages containing FILE.

Search only locally installed packages by default.  With a prefix
argument, try to search packages not yet installed.

You may use ARGS to pass options to the package manager."
  (interactive "FFile name: ")
  (if current-prefix-arg
      (oreo-packages--run-command 'owning-file-remote file args)
    (oreo-packages--run-command 'owning-file file args)))

;;;###autoload
(defun oreo-packages-change-log (pack &optional args)
  "Show the change log of PACK.

You may use ARGS to pass options to the package manager."
  (interactive "sPackage to show change log of: ")
  (oreo-packages--run-command 'change-log pack args))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions that don't take a named package
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun oreo-packages-update (&optional args)
  "Update system packages.

Use the package manager `oreo-packages-package-manager'.  You
may use ARGS to pass options to the package manger."
  (interactive)
  (oreo-packages--run-command 'update nil args))

;;;###autoload
(defun oreo-packages-remove-orphaned (&optional args)
  "Remove orphaned packages.

Uses the package manager named in
`oreo-packages-package-manager'.  You may use ARGS to pass
options to the package manger."
  (interactive)
  (oreo-packages--run-command 'remove-orphaned nil args))

;;;###autoload
(defun oreo-packages-list-installed-packages (all &optional args)
  "List explicitly installed packages.

Uses the package manager named in
`oreo-packages-package-manager'.  With
\\[universal-argument] (for ALL), list all installed packages.
You may use ARGS to pass options to the package manger."
  (interactive "P")
  (if all
      (oreo-packages--run-command 'list-installed-packages-all nil args)
    (oreo-packages--run-command 'list-installed-packages nil args)))

;;;###autoload
(defun oreo-packages-clean-cache (&optional args)
  "Clean the cache of the package manager.

You may use ARGS to pass options to the package manger."
  (interactive)
  (oreo-packages--run-command 'clean-cache nil args))

;;;###autoload
(defun oreo-packages-log (&optional args)
  "Show a log from `oreo-packages-package-manager'.

You may use ARGS to pass options to the package manger."
  (interactive)
  (oreo-packages--run-command 'log args))

;;;###autoload
(defun oreo-packages-verify-all-packages (&optional args)
  "Check that files owned by packages are present on the system.

You may use ARGS to pass options to the package manger."
  (interactive)
  (oreo-packages--run-command 'verify-all-packages nil args))

;;;###autoload
(defun oreo-packages-verify-all-dependencies (&optional args)
  "Verify that all required dependencies are installed on the system.

You may use ARGS to pass options to the package manger."
  (interactive)
  (oreo-packages--run-command 'verify-all-dependencies nil args))

(provide 'oreo-packages)
;;; oreo-packages.el ends here
