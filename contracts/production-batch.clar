;; Production Batch Contract
;; Tracks specific manufacturing runs

(define-data-var contract-owner principal tx-sender)

;; Data structure for production batches
(define-map production-batches
  { batch-id: uint }
  {
    product-name: (string-utf8 100),
    supplier-ids: (list 10 uint),
    material-test-ids: (list 10 uint),
    production-date: uint,
    quantity: uint,
    status: (string-utf8 50),
    quality-score: uint,
    producer: principal
  }
)

;; Track all batch IDs for enumeration
(define-data-var next-batch-id uint u1)

;; Authorization check
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Record a new production batch
(define-public (record-batch
  (product-name (string-utf8 100))
  (supplier-ids (list 10 uint))
  (material-test-ids (list 10 uint))
  (quantity uint)
  (status (string-utf8 50))
  (quality-score uint))
  (let
    (
      (batch-id (var-get next-batch-id))
    )
    ;; In a real implementation, we would check if the caller is an authorized producer
    ;; For simplicity, we're allowing the contract owner to record batches
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized

    ;; Insert the batch data
    (map-insert production-batches
      { batch-id: batch-id }
      {
        product-name: product-name,
        supplier-ids: supplier-ids,
        material-test-ids: material-test-ids,
        production-date: block-height,
        quantity: quantity,
        status: status,
        quality-score: quality-score,
        producer: tx-sender
      })

    ;; Increment the batch ID counter
    (var-set next-batch-id (+ batch-id u1))

    (ok batch-id)
  )
)

;; Update batch status
(define-public (update-batch-status (batch-id uint) (status (string-utf8 50)) (quality-score uint))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? production-batches { batch-id: batch-id })) (err u404)) ;; Batch not found

    (map-set production-batches
      { batch-id: batch-id }
      (merge (unwrap-panic (map-get? production-batches { batch-id: batch-id }))
        {
          status: status,
          quality-score: quality-score
        }
      )
    )

    (ok true)
  )
)

;; Get batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? production-batches { batch-id: batch-id })
)

;; Check batch quality score
(define-read-only (get-quality-score (batch-id uint))
  (default-to u0 (get quality-score (map-get? production-batches { batch-id: batch-id })))
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (var-set contract-owner new-owner)
    (ok true)
  )
)
