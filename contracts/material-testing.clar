;; Material Testing Contract
;; Records laboratory analysis results for materials

(define-data-var contract-owner principal tx-sender)

;; Data structure for material test results
(define-map material-tests
  { test-id: uint }
  {
    material-name: (string-utf8 100),
    supplier-id: uint,
    batch-number: (string-utf8 50),
    test-date: uint,
    test-type: (string-utf8 100),
    test-result: (string-utf8 200),
    passed: bool,
    tester: principal
  }
)

;; Track all test IDs for enumeration
(define-data-var next-test-id uint u1)

;; Authorization check
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Record a new material test (only by authorized testers)
(define-public (record-test
  (material-name (string-utf8 100))
  (supplier-id uint)
  (batch-number (string-utf8 50))
  (test-type (string-utf8 100))
  (test-result (string-utf8 200))
  (passed bool))
  (let
    (
      (test-id (var-get next-test-id))
    )
    ;; In a real implementation, we would check if the caller is an authorized tester
    ;; For simplicity, we're allowing the contract owner to record tests
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized

    ;; Insert the test data
    (map-insert material-tests
      { test-id: test-id }
      {
        material-name: material-name,
        supplier-id: supplier-id,
        batch-number: batch-number,
        test-date: block-height,
        test-type: test-type,
        test-result: test-result,
        passed: passed,
        tester: tx-sender
      })

    ;; Increment the test ID counter
    (var-set next-test-id (+ test-id u1))

    (ok test-id)
  )
)

;; Update an existing test result (only by contract owner)
(define-public (update-test-result (test-id uint) (test-result (string-utf8 200)) (passed bool))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? material-tests { test-id: test-id })) (err u404)) ;; Test not found

    (map-set material-tests
      { test-id: test-id }
      (merge (unwrap-panic (map-get? material-tests { test-id: test-id }))
        {
          test-result: test-result,
          passed: passed,
          test-date: block-height
        }
      )
    )

    (ok true)
  )
)

;; Get test information
(define-read-only (get-test (test-id uint))
  (map-get? material-tests { test-id: test-id })
)

;; Check if a material test passed
(define-read-only (did-test-pass (test-id uint))
  (default-to false (get passed (map-get? material-tests { test-id: test-id })))
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (var-set contract-owner new-owner)
    (ok true)
  )
)
