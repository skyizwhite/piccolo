(defpackage #:hsx/defhsx
  (:use #:cl)
  (:import-from #:alexandria
                #:make-keyword
                #:symbolicate)
  (:import-from #:hsx/element
                #:create-element)
  (:export #:deftag
           #:defcomp))
(in-package #:hsx/defhsx)

(defmacro defhsx (name element-type)
  `(defmacro ,name (&body body)
     `(%create-element ,',element-type ,@body)))

(defun %create-element (type &rest body)
  (multiple-value-bind (props children)
      (parse-body body)
    (create-element type props children)))

(defun parse-body (body)
  (cond ((and (listp (first body))
              (keywordp (first (first body))))
         (values (first body) (rest body)))
        ((keywordp (first body))
         (loop :for thing :on body :by #'cddr
               :for (k v) := thing
               :when (and (keywordp k) v)
               :append (list k v) :into props
               :when (not (keywordp k))
               :return (values props thing)
               :finally (return (values props nil))))
        (t (values nil body))))

(defmacro deftag (name)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (defhsx ,name ,(make-keyword name))))

(defmacro defcomp (name props &body body)
  (unless (or (null props)
              (member '&key props)
              (member '&rest props))
    (error "Component properties must be declared with either &key, &rest, or both."))
  (let ((%name (symbolicate '% name)))
    `(eval-when (:compile-toplevel :load-toplevel :execute)
       (defun ,%name ,props
         ,@body)
       (defhsx ,name (fdefinition ',%name)))))
