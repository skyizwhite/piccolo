(defpackage #:hsx/element
  (:use #:cl)
  (:export #:element-type
           #:element-props
           #:element-children
           #:create-element
           #:expand-component))
(in-package #:hsx/element)


;;;; class definitions

(defclass element ()
  ((type
    :reader element-type
    :initarg :type)
   (props
    :reader element-props
    :initarg :props)
   (children
    :reader element-children
    :initarg :children)))

(defclass tag-element (element) ())

(defclass html-tag-element (tag-element) ())

(defclass fragment-element (element) ())

(defclass component-element (element) ())


;;;; factory

(defun create-element (type props &rest children)
  (let ((elm (make-instance (cond ((functionp type) 'component-element)
                                  ((eq type :<>) 'fragment-element)
                                  ((eq type :html) 'html-tag-element)
                                  ((keywordp type) 'tag-element)
                                  (t (error "element-type must be either a keyword or a function.")))
                            :type type
                            :props props
                            :children (flatten children))))
    (create-element-hook elm)
    elm))

(defun flatten (x)
  (labels ((rec (x acc)
             (cond ((null x) acc)
                   ((atom x) (cons x acc))
                   (t (rec
                       (car x)
                       (rec (cdr x) acc))))))
    (rec x nil)))

(defmethod create-element-hook ((elm element)))

(defmethod create-element-hook ((elm fragment-element))
  (when (element-props elm)
    (error "Cannot pass props to fragment.")))

(defmethod create-element-hook ((elm component-element))
  ;dry-run to validate props
  (expand-component elm))


;;;; methods

(defmethod print-object ((elm tag-element) stream)
  (with-accessors ((type element-type)
                   (props element-props)
                   (children element-children)) elm
    (let ((type-str (string-downcase type)))
      (if children
          (format stream (if (rest children)
                             "~@<<~a~a>~2I~:@_~<~@{~a~^~:@_~}~:>~0I~:@_</~a>~:>"
                             "~@<<~a~a>~2I~:_~<~a~^~:@_~:>~0I~_</~a>~:>")
                  type-str
                  (props->string props)
                  children
                  type-str)
          (format stream "<~a~a></~a>"
                  type-str
                  (props->string props)
                  type-str)))))

(defun props->string (props)
  (with-output-to-string (stream)
    (loop
      :for (key value) :on props :by #'cddr
      :do (format stream (if (typep value 'boolean)
                             "~@[ ~a~]"
                             " ~a=\"~a\"")
                  (string-downcase key)
                  value))))

(defmethod print-object ((elm html-tag-element) stream)
  (format stream "<!DOCTYPE html>~%")
  (call-next-method))

(defmethod print-object ((elm fragment-element) stream)
  (with-accessors ((children element-children)) elm
    (if children
        (format stream (if (rest children)
                           "~<~@{~a~^~:@_~}~:>"
                           "~<~a~:>")
                children))))

(defmethod print-object ((elm component-element) stream)
  (print-object (expand-component elm) stream))

(defmethod expand-component ((elm component-element))
  (with-accessors ((type element-type)
                   (props element-props)
                   (children element-children)) elm
    (apply type (merge-children-into-props props children))))

(defun merge-children-into-props (props children)
  (append props
          (and children
               (list :children children))))
