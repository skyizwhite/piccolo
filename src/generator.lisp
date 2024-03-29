(uiop:define-package #:piccolo/generator
  (:use #:cl)
  (:local-nicknames (#:alx #:alexandria))
  (:local-nicknames (#:elm #:piccolo/elements))
  (:export #:*expand-user-element*
           #:element-string
           #:elem-str))
(in-package #:piccolo/generator)

;;; groups of specific tags and attributes

(defun symbols-hash-table (symbols)
  (let ((ht (make-hash-table)))
    (mapcar (lambda (sym)
              (setf (gethash (alx:make-keyword sym) ht) t))
            symbols)
    ht))

(defmacro define-group (name &body symbols)
  (alx:with-gensyms (ht)
    `(progn
       (let ((,ht (symbols-hash-table ',symbols)))
         (defun ,(alx:symbolicate name '-p) (symbol)
           (gethash (alx:make-keyword (string-upcase symbol)) ,ht))))))

(define-group self-closing-tag
  area base br col embed hr img input keygen
  link meta param source track wbr)

;;; print-object

(defparameter *expand-user-element* t)

(defmethod print-object ((attrs elm:attrs) stream)
  (loop 
    :for (key . value) :in (elm:attrs-alist attrs)
    :do (format stream (if (typep value 'boolean)
                           "~@[ ~a~]"
                           " ~a=~s")
                (string-downcase key)
                value)))

(defmethod print-object ((element elm:element) stream)
  (if (elm:element-children element)
      (format stream (if (rest (elm:element-children element))
                         "~@<<~a~a>~2I~:@_~<~@{~a~^~:@_~}~:>~0I~:@_</~a>~:>"
                         "~@<<~a~a>~2I~:_~<~a~^~:@_~:>~0I~_</~a>~:>")
              (elm:element-tag element)
              (elm:element-attrs element)
              (elm:element-children element)
              (elm:element-tag element))
      (format stream (if (self-closing-tag-p (elm:element-tag element))
                         "<~a~a>"
                         "<~a~a></~a>")
              (elm:element-tag element)
              (elm:element-attrs element)
              (elm:element-tag element))))

(defmethod print-object ((element elm:builtin-element-with-prefix) stream)
  (format stream "~a~%" (elm:element-prefix element))
  (call-next-method))

(defmethod print-object ((element elm:user-element) stream)
  (if *expand-user-element*
      (print-object (elm:user-element-expand-to element) stream)
      (call-next-method)))

(defmethod print-object ((element elm:fragment) stream)
  (if (elm:element-children element)
      (format stream (if (rest (elm:element-children element))
                         "~<~@{~a~^~:@_~}~:>"
                         "~<~a~:>")
              (elm:element-children element))))

;;; helper for generate html string

(defmethod element-string ((element elm:element))
  (with-output-to-string (s)
    (write element :stream s :pretty t)))

(defmethod elem-str ((element elm:element))
  (with-output-to-string (s)
    (write element :stream s :pretty nil)))
