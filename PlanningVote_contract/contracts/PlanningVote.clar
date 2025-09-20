
;; title: PlanningVote - Municipal Governance Platform
;; version: 1.0.0
;; summary: Smart contract for zoning decisions and urban development approvals
;; description: A decentralized platform for municipal governance allowing citizens and
;;              officials to participate in zoning and urban development decision-making

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-VOTING-NOT-ENDED (err u104))
(define-constant ERR-INVALID-PROPOSAL-TYPE (err u105))
(define-constant ERR-INVALID-VOTE (err u106))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant VOTING-DURATION u144) ;; ~24 hours in blocks (assuming 10 min blocks)

;; Proposal types
(define-constant ZONING-CHANGE u1)
(define-constant DEVELOPMENT-APPROVAL u2)
(define-constant LAND-USE-PERMIT u3)

;; Vote options
(define-constant VOTE-FOR u1)
(define-constant VOTE-AGAINST u2)
(define-constant VOTE-ABSTAIN u3)

;; Data variables
(define-data-var proposal-counter uint u0)
(define-data-var admin principal CONTRACT-OWNER)

;; Data maps
(define-map proposals
  uint ;; proposal-id
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: uint,
    proposer: principal,
    created-at: uint,
    voting-ends-at: uint,
    votes-for: uint,
    votes-against: uint,
    votes-abstain: uint,
    executed: bool,
    passed: bool
  }
)

(define-map votes
  {proposal-id: uint, voter: principal}
  {vote: uint, voted-at: uint}
)

(define-map authorized-officials
  principal
  bool
)

(define-map citizen-registrations
  principal
  {registered-at: uint, active: bool}
)

;; Public functions

;; Register as a citizen to participate in voting
(define-public (register-citizen)
  (begin
    (map-set citizen-registrations
      tx-sender
      {registered-at: block-height, active: true}
    )
    (ok true)
  )
)

;; Admin function to authorize municipal officials
(define-public (authorize-official (official principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (map-set authorized-officials official true)
    (ok true)
  )
)

;; Create a new proposal (only authorized officials can create proposals)
(define-public (create-proposal
  (title (string-ascii 100))
  (description (string-ascii 500))
  (proposal-type uint))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (current-height block-height)
    )
    (asserts! (default-to false (map-get? authorized-officials tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (or (is-eq proposal-type ZONING-CHANGE)
                  (is-eq proposal-type DEVELOPMENT-APPROVAL)
                  (is-eq proposal-type LAND-USE-PERMIT)) ERR-INVALID-PROPOSAL-TYPE)

    (map-set proposals
      proposal-id
      {
        title: title,
        description: description,
        proposal-type: proposal-type,
        proposer: tx-sender,
        created-at: current-height,
        voting-ends-at: (+ current-height VOTING-DURATION),
        votes-for: u0,
        votes-against: u0,
        votes-abstain: u0,
        executed: false,
        passed: false
      }
    )

    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Vote on a proposal (registered citizens can vote)
(define-public (vote-on-proposal (proposal-id uint) (vote uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (voter-registration (map-get? citizen-registrations tx-sender))
      (existing-vote (map-get? votes {proposal-id: proposal-id, voter: tx-sender}))
    )
    (asserts! (is-some voter-registration) ERR-NOT-AUTHORIZED)
    (asserts! (get active (unwrap-panic voter-registration)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
    (asserts! (<= block-height (get voting-ends-at proposal)) ERR-VOTING-ENDED)
    (asserts! (or (is-eq vote VOTE-FOR)
                  (is-eq vote VOTE-AGAINST)
                  (is-eq vote VOTE-ABSTAIN)) ERR-INVALID-VOTE)

    ;; Record the vote
    (map-set votes
      {proposal-id: proposal-id, voter: tx-sender}
      {vote: vote, voted-at: block-height}
    )

    ;; Update vote counts
    (if (is-eq vote VOTE-FOR)
      (map-set proposals
        proposal-id
        (merge proposal {votes-for: (+ (get votes-for proposal) u1)})
      )
      (if (is-eq vote VOTE-AGAINST)
        (map-set proposals
          proposal-id
          (merge proposal {votes-against: (+ (get votes-against proposal) u1)})
        )
        (map-set proposals
          proposal-id
          (merge proposal {votes-abstain: (+ (get votes-abstain proposal) u1)})
        )
      )
    )

    (ok true)
  )
)

;; Execute a proposal after voting period ends
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
    )
    (asserts! (> block-height (get voting-ends-at proposal)) ERR-VOTING-NOT-ENDED)
    (asserts! (not (get executed proposal)) ERR-NOT-AUTHORIZED)

    (let
      (
        (total-votes (+ (+ (get votes-for proposal) (get votes-against proposal)) (get votes-abstain proposal)))
        (votes-for (get votes-for proposal))
        (votes-against (get votes-against proposal))
        (passed (> votes-for votes-against))
      )

      (map-set proposals
        proposal-id
        (merge proposal {executed: true, passed: passed})
      )

      (ok {executed: true, passed: passed, total-votes: total-votes})
    )
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get vote by voter for a specific proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Check if an address is an authorized official
(define-read-only (is-authorized-official (address principal))
  (default-to false (map-get? authorized-officials address))
)

;; Check if an address is a registered citizen
(define-read-only (is-registered-citizen (address principal))
  (match (map-get? citizen-registrations address)
    registration (get active registration)
    false
  )
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

;; Get voting results for a proposal
(define-read-only (get-voting-results (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (ok {
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      votes-abstain: (get votes-abstain proposal),
      total-votes: (+ (+ (get votes-for proposal) (get votes-against proposal)) (get votes-abstain proposal)),
      executed: (get executed proposal),
      passed: (get passed proposal)
    })
    ERR-PROPOSAL-NOT-FOUND
  )
)

;; Check if voting is still active for a proposal
(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (<= block-height (get voting-ends-at proposal))
    false
  )
)

;; Get contract admin
(define-read-only (get-admin)
  (var-get admin)
)

;; Private functions

;; Helper function to validate proposal type
(define-private (is-valid-proposal-type (proposal-type uint))
  (or
    (is-eq proposal-type ZONING-CHANGE)
    (is-eq proposal-type DEVELOPMENT-APPROVAL)
    (is-eq proposal-type LAND-USE-PERMIT)
  )
)

;; Helper function to validate vote option
(define-private (is-valid-vote (vote uint))
  (or
    (is-eq vote VOTE-FOR)
    (is-eq vote VOTE-AGAINST)
    (is-eq vote VOTE-ABSTAIN)
  )
)
