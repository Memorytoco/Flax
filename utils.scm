;; NOTE : done
(define-module (Flax utils)
               #:use-module (ice-9 ftw)
               #:use-module (ice-9 match)
               #:use-module (srfi srfi-1)
               #:use-module (srfi srfi-13)
               #:use-module (srfi srfi-19)
               #:use-module (srfi srfi-26)

               #:export (get-absolute-path
                         decompose-file-name
                         compose-file-name
                         mkdir-p
                         delete-file-recursively
                         make-user-module
                         remove-stat
                         get-file-tree-list))
;; return the absolute path of the file
;; TODO : need to do better
(define (get-absolute-path file-name)
  (if (absolute-file-name? file-name)
      file-name
      (string-append (getcwd) "/" file-name)))

;; decompose a string
;; example
;; "////usr/lib/share" => ("usr" "lib" "share")
(define (decompose-file-name filename)
  "split filename into components seperated by '/' "
  (match filename
    ("" '())      ;; if string is empty
    ("/" '(""))   ;; if string only has one '/'
    (_ (delete "" (string-split filename #\/)))))

;; components is a list of strings
;; like ("hello" "nice" "good") => /hello/nice/good
(define (compose-file-name components)
  (string-join components "/" 'prefix))

;; create directory
(define (mkdir-p dir)
  "create directory ~dir~ and all its ancestors"
  (define absolute?
    (string-prefix? "/" dir))

  (define not-slash
    ;; get all complement of charset #<charset {#\null #\. #\0 ....}>
    (char-set-complement (char-set #\/)))

  (let loop ((components (string-tokenize dir not-slash))
            (root        (if absolute?
                             ""
                             ".")))
    (match components
      ((head tail ...)
       (let ((path (string-append root "/" head)))
         (catch 'system-errors
           ;; NOTE : couldn't understand
           (lambda ()
             (mkdir path)
             (loop tail path))
           (lambda (args)
             (if (= EEXIST (system-error-errno args))
                 (loop tail path)
                 (apply throw args))))))
      (() #t))))

;; remove the file tree list stat and return
;; the ~file-tree-list~ is the value of procedure
;; ~file-system-tree~ which is in (ice-9 ftw)
(define (remove-stat file-tree-list)
  (match file-tree-list
    ((name stat)
      name)
    ((name stat children ... )
      (cons (car file-tree-list) (map remove-stat children)))))

;; if file-name is a file,return the file name
;; if the file-name is a directory, return the tree list of the directory
;; just like execute "tree file-name"
(define (get-file-tree-list file-name)
  (remove-stat (file-system-tree file-name)))

;; delete file
(define* (delete-file-recursively dir #:key follow-mounts?)
"Delete DIR recursively, like `rm -rf', without following symlinks.  Don't
follow mount points either, unless FOLLOW-MOUNTS? is true.  Report but ignore
errors."
  (let ((dev (stat:dev (lstat dir))))
    (file-system-fold (lambda (dir stat result)    ; enter?
                        (or follow-mounts?
                          (= dev (stat:dev stat))))
                      (lambda (file stat result)   ; leaf
                          (delete-file file))
                      (const #t)                   ; down
                      (lambda (dir stat result)    ; up
                      (rmdir dir))
                      (const #t)                   ; skip
                      (lambda (file stat errno result)
                        (format (current-error-port)
                      "warning: failed to delete ~a: ~a~%"
                            file (strerror errno)))
                      #t
                      dir

                      ;; Don't follow symlinks.
                      lstat)))

;; return a new user module with the additional modules
;; loaded
(define make-user-module
  (lambda (modules)
    (let ((module (make-fresh-user-module)))
      (for-each (lambda (iface)
                  (module-use! module (resolve-interface iface)))
                modules)
      module)))