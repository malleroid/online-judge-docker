(require :sb-gmp)
(require :sb-mpfr)
(require :sb-queue)
(require :sb-rotate-byte)
(require :sb-simd)
(progn
  (let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                            (user-homedir-pathname))))
    (when (probe-file quicklisp-init)
      (load quicklisp-init)))

(sb-ext:save-lisp-and-die "sbcl" :executable t :save-runtime-options t))
