#lang plait

(module+ test
  (print-only-errors #t))

;; abstract syntax -------------------------------

(define-type Op
  (add) (sub) (mul))

(define-type Exp
  (numE [n : Number])
  (opE [op : Op] [e1 : Exp] [e2 : Exp])
  (varE [x : Symbol])
  (lamE [x : Symbol] [e : Exp])
  (appE [e0 : Exp] [e1 : Exp])
  (countE))

;; semantics: the identity monad and values


(define-type-alias State Number)
(define-type-alias (M 'a) (State -> ('a * State)))


(define (returnM [v : 'a]) : (M 'a)
  (λ ([s : State]) (pair v s)))

(define (bindM [c : (M 'a)] [f : ('a -> (M 'b))]) : (M 'b)
  (lambda (s)
    (let* ([cs (c s)])
      ((f (fst cs)) (snd cs)))))

(define (errorM [l : Symbol] [m : String]) : (M 'a)
  (error l m))

(define (showM [c : (M Value)]) : String
  (let* ([cs (c 0)]
         [new-c (fst cs)]
         [new-s (snd cs)])
    (string-append "value: " (string-append (value->string new-c) (string-append ", state: " (to-string new-s))))))

(define tickM : (M Void)
  (lambda (s) (pair (void) (+ s 1))))

(define-type Value
  (numV [n : Number])
  (funV [f : (Value -> (M Value))]))

(define (value->string [v : Value]) : String
  (type-case Value v
    [(numV n) (to-string n)]
    [(funV _) "#<procedure>"]))

;; environments

(define-type Binding
  (bind [name : Symbol]
        [val : Value]))

(define-type-alias Env (Listof Binding))

(define mt-env empty)

(define (extend-env [env : Env] [x : Symbol] [v : Value]) : Env
  (cons (bind x v) env))

(define (lookup-env [x : Symbol] [env : Env]) : (M Value)
  (type-case (Listof Binding) env
    [empty
     (errorM 'lookup-env "unbound variable")]
    [(cons b rst-env)
     (cond
       [(eq? x (bind-name b))
        (returnM (bind-val b))]
       [else
        (lookup-env x rst-env)])]))

;; primitive operations

(define (op-num-num->proc [f : (Number Number -> Number)]) : (Value Value -> (M Value))
  (λ (v1 v2)
    (type-case Value v1
      [(numV n1)
       (type-case Value v2
         [(numV n2)
          (returnM (numV (f n1 n2)))]
         [else
          (errorM 'prim-op "not a number")])]
      [else
       (errorM 'prim-op "not a number")])))

(define (op->proc [op : Op]) : (Value Value -> (M Value))
  (type-case Op op
    [(add) (op-num-num->proc +)]
    [(sub) (op-num-num->proc -)]
    [(mul) (op-num-num->proc *)]))

;; evaluation function (eval/apply)

(define-syntax do
  (syntax-rules ()
    [(do () a)
     a]
    [(do ([x1 a1] [x2 a2] ...) a)
     (bindM a1 (λ (x1) (do ([x2 a2] ...) a)))]))

(define (eval [e : Exp] [env : Env]) : (M Value)
  (type-case Exp e
    [(numE n)
     (returnM (numV n))]
    [(opE o e1 e2)
     (do ([v1 (eval e1 env)]
          [v2 (eval e2 env)]
          [v3 tickM])
       ((op->proc o) v1 v2))]
    [(varE x)
     (lookup-env x env)]
    [(lamE x b)
     (returnM (funV (λ (v) (eval b (extend-env env x v)))))]
    [(appE e0 e1)
     (bindM (eval e0 env)
            (λ (v0) (bindM (eval e1 env)
                           (λ (v1) (bindM tickM
                                          (λ (v3) (apply v0 v1)))))))]
    [(countE)
     (λ (s) (pair (numV s) s))]))
            

(define (apply [v0 : Value] [v1 : Value]) : (M Value)
  (type-case Value v0
    [(funV f) (f v1)]
    [else (errorM 'apply "not a function")]))

(define (run [e : S-Exp]) : String
  (showM (eval (parse e) mt-env)))

( module+ test
   ( test ( run `2)
          "value: 2, state: 0")
   ( test ( run `{+ {* 2 3} {+ 5 8}})
          "value: 19, state: 3")
   ( test ( run `{{ lambda { x } {+ x 1}} 5})
          "value: 6, state: 2")
   ( test/exn ( run `{1 2})
              "not a function")
   ( test ( run `{+ {+ count count }
                     {+ count count }})
          "value: 2, state: 3") )



;(module+ test
;  (test (run `2)
;        "2")
;  (test (run `{+ 2 1})
;        "3")
;  (test (run `{* 2 1})
;        "2")
;  (test (run `{+ {* 2 3} {+ 5 8}})
;        "19")
;  (test (run `{{lambda {x} {+ x 1}} 5})
;        "6")
;  (test (run `{lambda {x} {+ x 1}})
;        "#<procedure>")
;  (test/exn (run `{1 2})
;            "not a function")
;  (test/exn (run `x)
;            "unbound variable")
;  (test/exn (run `{+ 1 {lambda {x} x}})
;            "not a number"))

;; parse ----------------------------------------

(define (parse [s : S-Exp]) : Exp
  (cond
    [(s-exp-match? `count s)
     (countE)]
    [(s-exp-match? `NUMBER s)
     (numE (s-exp->number s))]
    [(s-exp-match? `{lambda {SYMBOL} ANY} s)
     (lamE (s-exp->symbol
            (first (s-exp->list 
                    (second (s-exp->list s)))))
           (parse (third (s-exp->list s))))]
    [(s-exp-match? `{SYMBOL ANY ANY} s)
     (opE (parse-op (s-exp->symbol (first (s-exp->list s))))
          (parse (second (s-exp->list s)))
          (parse (third (s-exp->list s))))]
    [(s-exp-match? `SYMBOL s)
     (varE (s-exp->symbol s))]
    [(s-exp-match? `{ANY ANY} s)
     (appE (parse (first (s-exp->list s)))
           (parse (second (s-exp->list s))))]
    [else (error 'parse "invalid input")]))

(define (parse-op [op : Symbol]) : Op
  (cond
    [(eq? op '+) (add)]
    [(eq? op '-) (sub)]
    [(eq? op '*) (mul)]
    [else (error 'parse "unknown operator")]))



