;; the page data type
;; TODO: unfinished file
(define-module (Flax page)
    #:use-module (ice-9 match)
    #:use-module (srfi srfi-9)
    #:use-module (srfi srfi-26)
    #:use-module (Flax utils)

    #:export (make-page
              is-page?
              get-page-file-name
              get-page-contents
              get-page-writer
              write-page
	      create-writer))
;;
;; define the record <page>
;; ~file-name~ is a string
;; ~contents~ is 
(define-record-type <page>
    (make-page file-name contents writer)
    is-page?
    (file-name get-page-file-name)
    (contents  get-page-contents)
    (writer    get-page-writer))

;; write the rendered page to one directory
;; the directory can be a path
(define (write-page page output-directory)
  (match page
    (($ <page> file-name contents writer)
     (let ((output (string-append output-directory "/" file-name)))
       (mkdir-p (dirname output))
       (call-with-output-file output (cut writer contents <>))))))

;; create the default writer for page
(define (create-writer)
  (lambda (contents port)
    (display contents port)))
