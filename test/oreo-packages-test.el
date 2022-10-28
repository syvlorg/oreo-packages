;;; oreo-packages-test.el --- ERT testing framework for oreo-packages.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Free Software Foundation, Inc.

;; Author: J. Alexander Branham <alex.branham@gmail.com>

(require 'ert)
(require 'oreo-packages)

(ert-deftest oreo-packages-get-install ()
  "Return correct installation command."
  (should (string=
           (let ((oreo-packages-use-sudo nil)
                 (oreo-packages-package-manager 'guix))
             (oreo-packages-get-command 'install))
           "guix package -i "))
  (should (string=
           (let ((oreo-packages-use-sudo nil)
                 (oreo-packages-package-manager 'pacman))
             (oreo-packages-get-command 'install))
           "pacman -S ")))

(ert-deftest oreo-packages-get-install-noconfirm ()
  "Return correct installation command."
  (should (string=
           (let ((oreo-packages-noconfirm t)
                 (oreo-packages-use-sudo nil)
                 (oreo-packages-package-manager 'guix))
             (oreo-packages-get-command 'install))
           "guix package -i "))
  (should (string=
           (let ((oreo-packages-noconfirm t)
                 (oreo-packages-use-sudo nil)
                 (oreo-packages-package-manager 'pacman))
             (oreo-packages-get-command 'install))
           "pacman -S --noconfirm"))
  (should (string=
           (let ((oreo-packages-noconfirm t)
                 (oreo-packages-use-sudo nil)
                 (oreo-packages-package-manager 'apt))
             (oreo-packages-get-command 'install "rg"))
           "apt-get install rg -y")))

(ert-deftest oreo-packages-errors ()
  "Error when we don't know a command."
  (should-error
   (let ((oreo-packages-package-manager 'pacaur))
     (oreo-packages-get-command 'install))))

;;; oreo-packages-test.el ends here
