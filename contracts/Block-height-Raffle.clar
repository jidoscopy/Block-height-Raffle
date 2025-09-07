;; Block-height Raffle Contract
;; A lottery that picks winners based on unpredictable Bitcoin block hashes

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_RAFFLE_NOT_ACTIVE (err u101))
(define-constant ERR_RAFFLE_ENDED (err u102))
(define-constant ERR_ALREADY_ENTERED (err u103))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u104))
(define-constant ERR_WINNER_ALREADY_SELECTED (err u105))
(define-constant ERR_NOT_WINNER (err u106))

;; Data variables
(define-data-var raffle-id uint u0)
(define-data-var entry-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var raffle-active bool false)
(define-data-var target-block-height uint u0)
(define-data-var winner-selected bool false)
(define-data-var winner (optional principal) none)
(define-data-var total-entries uint u0)

;; Maps
(define-map raffle-entries {raffle-id: uint, participant: principal} {entry-number: uint})
(define-map entry-numbers {raffle-id: uint, entry-number: uint} {participant: principal})

;; Read-only functions
(define-read-only (get-raffle-info)
  {
    raffle-id: (var-get raffle-id),
    entry-fee: (var-get entry-fee),
    active: (var-get raffle-active),
    target-block: (var-get target-block-height),
    total-entries: (var-get total-entries),
    winner: (var-get winner)
  }
)

(define-read-only (has-entered (participant principal))
  (is-some (map-get? raffle-entries {raffle-id: (var-get raffle-id), participant: participant}))
)

;; Public functions
(define-public (start-raffle (blocks-ahead uint) (new-entry-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (var-set raffle-id (+ (var-get raffle-id) u1))
    (var-set entry-fee new-entry-fee)
    (var-set raffle-active true)
    (var-set target-block-height (+ block-height blocks-ahead))
    (var-set winner-selected false)
    (var-set winner none)
    (var-set total-entries u0)
    (ok (var-get raffle-id))
  )
)

(define-public (enter-raffle)
  (let (
    (current-raffle-id (var-get raffle-id))
    (current-total (var-get total-entries))
  )
    (asserts! (var-get raffle-active) ERR_RAFFLE_NOT_ACTIVE)
    (asserts! (< block-height (var-get target-block-height)) ERR_RAFFLE_ENDED)
    (asserts! (not (has-entered tx-sender)) ERR_ALREADY_ENTERED)

    (try! (stx-transfer? (var-get entry-fee) tx-sender (as-contract tx-sender)))

    (map-set raffle-entries 
      {raffle-id: current-raffle-id, participant: tx-sender}
      {entry-number: current-total}
    )
    (map-set entry-numbers
      {raffle-id: current-raffle-id, entry-number: current-total}
      {participant: tx-sender}
    )
    (var-set total-entries (+ current-total u1))
    (ok current-total)
  )
)

(define-public (select-winner)
  (let (
    (current-raffle-id (var-get raffle-id))
    (total (var-get total-entries))
  )
    (asserts! (>= block-height (var-get target-block-height)) ERR_RAFFLE_NOT_ACTIVE)
    (asserts! (not (var-get winner-selected)) ERR_WINNER_ALREADY_SELECTED)
    (asserts! (> total u0) ERR_RAFFLE_NOT_ACTIVE)

    (let (
      (block-hash (unwrap-panic (get-block-info? header-hash (var-get target-block-height))))
      (byte-0 (unwrap-panic (element-at block-hash u0)))
      (byte-1 (unwrap-panic (element-at block-hash u1)))
      (byte-2 (unwrap-panic (element-at block-hash u2)))
      (byte-3 (unwrap-panic (element-at block-hash u3)))
      (hash-number (+ (* (buff-to-uint-be byte-0) u16777216) (* (buff-to-uint-be byte-1) u65536) (* (buff-to-uint-be byte-2) u256) (buff-to-uint-be byte-3)))
      (random-number (mod hash-number total))
      (winning-entry (unwrap-panic (map-get? entry-numbers 
        {raffle-id: current-raffle-id, entry-number: random-number})))
    )
      (var-set winner (some (get participant winning-entry)))
      (var-set winner-selected true)
      (var-set raffle-active false)
      (ok (get participant winning-entry))
    )
  )
)

(define-public (claim-prize)
  (let (
    (prize-amount (* (var-get entry-fee) (var-get total-entries)))
  )
    (asserts! (var-get winner-selected) ERR_WINNER_ALREADY_SELECTED)
    (asserts! (is-eq (some tx-sender) (var-get winner)) ERR_NOT_WINNER)

    (try! (as-contract (stx-transfer? prize-amount tx-sender tx-sender)))
    (ok prize-amount)
  )
)

