(in-package :ghostie)

(defun get-bodies-from-arbiter (arbiter)
  "Given an arbiter, get the two game bodies (cpw) that collided."
  (cffi:with-foreign-objects ((a :pointer)
                              (b :pointer))
    (cp-f:arbiter-get-shapes arbiter a b)
    (let ((body-a (cpw:find-body-from-pointer (cp-a:shape-body (cffi:mem-aref a :pointer))))
          (body-b (cpw:find-body-from-pointer (cp-a:shape-body (cffi:mem-aref b :pointer)))))
      (values body-a body-b))))

(defun reverse-normals (arbiter)
  "Given an arbiter, reverse the contact normals (and save the reversed normals
   back into the original arbiter)."
  (let ((normals (cpw:arbiter-normals arbiter)))
    (setf (cpw:arbiter-normals arbiter)
          (mapcar (lambda (normal)
                    (mapcar #'- normal))
                  normals))
    arbiter))

(defmacro define-collision-callback (name (arbiter-var body1-var body2-var &key (sync t)) &body body)
  `(defun ,name (arbiter space data)
     (declare (ignore space data))
     ;; let's be careful here since a condition can derail chipmunk and creash
     ;; the entire app
     (handler-case
       (multiple-value-bind (,body1-var ,body2-var)
           (get-bodies-from-arbiter arbiter)
         (let ((,arbiter-var (cpw:make-arbiter arbiter)))
           ,@body
           (when ,sync (cpw:sync-arbiter-to-c ,arbiter-var))
           (if (cpw:arbiter-ignore-collision ,arbiter-var)
               cp:+false+
               cp:+true+)))
       (condition (e)
         (dbg :error "(physics) Collision event error (~a): ~a~%" ',name e)
         cp:+true+))))

(define-collision-callback collision-begin (arbiter-data body1 body2)
  (let ((obj1 (cpw:body-data body1))
        (obj2 (cpw:body-data body2)))
    (trigger :collision-begin obj1 obj2 arbiter-data)
    (trigger :collision-begin obj2 obj1 (reverse-normals arbiter-data))))

(define-collision-callback collision-pre-solve (arbiter-data body1 body2)
  (let ((obj1 (cpw:body-data body1))
        (obj2 (cpw:body-data body2)))
    (trigger :collision-pre obj1 obj2 arbiter-data)
    (trigger :collision-pre obj2 obj1 (reverse-normals arbiter-data))))

(define-collision-callback collision-post-solve (arbiter-data body1 body2)
  (let ((obj1 (cpw:body-data body1))
        (obj2 (cpw:body-data body2)))
    (trigger :collision-post obj1 obj2 arbiter-data)
    (trigger :collision-post obj2 obj1 (reverse-normals arbiter-data))))

(define-collision-callback collision-separate (arbiter-data body1 body2)
  (let ((obj1 (cpw:body-data body1))
        (obj2 (cpw:body-data body2)))
    (trigger :collision-separate obj1 obj2 arbiter-data)
    (trigger :collision-separate obj2 obj1 (reverse-normals arbiter-data))))

(cffi:defcallback cp-begin :int ((arb :pointer) (space :pointer) (data :pointer))
  (collision-begin arb space data))
(cffi:defcallback cp-pre-solve :int ((arb :pointer) (space :pointer) (data :pointer))
  (collision-pre-solve arb space data))
(cffi:defcallback cp-post-solve :void ((arb :pointer) (space :pointer) (data :pointer))
  (collision-post-solve arb space data))
(cffi:defcallback cp-separate :void ((arb :pointer) (space :pointer) (data :pointer))
  (collision-separate arb space data))

