open import Algebra

open import Data.Vec using (Vec ; [] ; _∷_ ; foldr ; _++_)
open import Data.Vec.Properties
open import Data.Vec.Equality

open import Data.Nat
open import Data.Nat.Properties
  using (n∸n≡0 ; commutativeSemiring)
open import Data.Product

open CommutativeSemiring commutativeSemiring 
  using (*-identity ; *-assoc)

open import Relation.Binary using (Rel ; REL ; Setoid)
open import Relation.Binary.PropositionalEquality
  renaming (isEquivalence to isEquiv)
open import Relation.Nullary

import Level

module J-Agda.JData.JShape where

Shape : ℕ → Set
Shape = Vec ℕ

*/ : ∀ {d} → Shape d → ℕ
*/ = foldr (λ _ → ℕ) _*_ 1

inspect-*/ : ∀ {d} → (sh : Shape d) → Σ[ x ∈ ℕ ] */ sh ≡ x
inspect-*/ sh = */ sh , refl


module Properties where

  */-++-commutes : ∀ {d₁ d₂} →(sh₁ : Shape d₁) → {sh₂ : Shape d₂} → 
                   */ (sh₁ ++ sh₂) ≡ (*/ sh₁) * (*/ sh₂)
  */-++-commutes [] {sh₂} = sym (proj₁ *-identity (*/ sh₂))
  */-++-commutes (s ∷ sh₁) {sh₂} = begin
    (s * (*/ (sh₁ ++ sh₂))
      ≡⟨ cong (λ x → s * x) (*/-++-commutes sh₁) ⟩
    (s * (*/ sh₁ * */ sh₂))
      ≡⟨ sym (*-assoc s (*/ sh₁) (*/ sh₂)) ⟩
    (*/ (s ∷ sh₁) * */ sh₂
      ∎))
    where open Relation.Binary.PropositionalEquality.≡-Reasoning


module ShapeAgreement where

    ExactShapeAgreement : ∀ {d} → Rel (Shape d) Level.zero
    ExactShapeAgreement {d} = _≡_

-- prefix agreement
    data Prefix : ∀ {d₁ d₂} → REL (Shape d₁) (Shape d₂) Level.zero where
      []-pref : ∀ {d} → (sh : Shape d) → Prefix [] sh
      ∷-pref  : ∀ {d₁ d₂} → (s : ℕ) → {sh₁ : Shape d₁} → {sh₂ : Shape d₂}
                → Prefix sh₁ sh₂ → Prefix (s ∷ sh₁) (s ∷ sh₂)

-- self is prefix
    self-prefix : ∀ {d} → (sh : Shape d) → Prefix sh sh
    self-prefix [] = []-pref []
    self-prefix (x ∷ sh) = ∷-pref x (self-prefix sh)


-- Suffix
    suffix : ∀ {d₁ d₂} → {sh₁ : Shape d₁} → {sh₂ : Shape d₂} → 
               Prefix sh₁ sh₂ → Shape (d₂ ∸ d₁)
    suffix {.0} {d₂} {.[]} {sh₂} ([]-pref .sh₂) = sh₂
    suffix (∷-pref s pre) = suffix pre

    suffix-len : ∀ {d₁ d₂} → {sh₁ : Shape d₁} → {sh₂ : Shape d₂} → 
                 Prefix sh₁ sh₂ → ℕ
    suffix-len {d₁ = d₁} {d₂ = d₂} _ = d₂ ∸ d₁

-- Self suffix
    self-suffix-len≡0 : ∀ {d} → {sh : Shape d } → ⦃ pre : Prefix sh sh ⦄ →
                        d ∸ d ≡ 0
    self-suffix-len≡0 {d = d} = n∸n≡0 d

    self-suffix≡[] : ∀ {d} → {sh : Shape d} → ⦃ pre : Prefix sh sh ⦄ → 
                    subst Shape (n∸n≡0 d) (suffix pre) ≡ []
    self-suffix≡[] {d = d} ⦃ pre = pre ⦄
        with subst Shape (n∸n≡0 d) (suffix pre)
    ... | [] = refl


-- helper function to unwrap a Prefix by the head argument
    pref-pred : ∀ {d₁ d₂ s} → {sh₁ : Shape d₁} → {sh₂ : Shape d₂}
                → Prefix (s ∷ sh₁) (s ∷ sh₂) → Prefix sh₁ sh₂
    pref-pred {d₁} {d₂} {s} (∷-pref .s pr) = pr

-- Prefix is decidable
    prefix? : ∀ {d₁ d₂} → (sh₁ : Shape d₁) → (sh₂ : Shape d₂) → Dec (Prefix sh₁ sh₂)
    prefix? [] sh₂ = yes ([]-pref sh₂)
    prefix? (x ∷ sh₁) [] = no (λ ())
    prefix? (x ∷ sh₁) (x₁ ∷ sh₂)   with x ≟ x₁ | prefix? sh₁ sh₂ 
    prefix? (.x₁ ∷ sh₁) (x₁ ∷ sh₂) | yes refl  | yes p = yes (∷-pref x₁ p)
    prefix? (.x₁ ∷ sh₁) (x₁ ∷ sh₂) | yes refl  | no ¬p = no (λ p∷ → ¬p (pref-pred p∷))
    prefix? (x ∷ sh₁) (x₁ ∷ sh₂)   | no ¬p     | pr = no (λ p∷ → ¬p (lemma p∷))
      where
        lemma : ∀ {x₁ x₂} → Prefix (x₁ ∷ sh₁) (x₂ ∷ sh₂) → x₁ ≡ x₂
        lemma {.x₂} {x₂} (∷-pref .x₂ pr₁) = refl