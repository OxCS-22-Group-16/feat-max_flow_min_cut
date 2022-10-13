/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Mario Carneiro, Johan Commelin, Amelia Livingston, Anne Baanen
-/
import ring_theory.adjoin_root

/-!
# Localizations away from an element

## Main definitions

 * `is_localization.away (x : R) S` expresses that `S` is a localization away from `x`, as an
   abbreviation of `is_localization (submonoid.powers x) S`

## Implementation notes

See `src/ring_theory/localization/basic.lean` for a design overview.

## Tags
localization, ring localization, commutative ring localization, characteristic predicate,
commutative ring, field of fractions
-/

section comm_semiring

variables {R : Type*} [comm_semiring R] (M : submonoid R) {S : Type*} [comm_semiring S]
variables [algebra R S] {P : Type*} [comm_semiring P]

namespace is_localization

section away

variables (x : R)

/-- Given `x : R`, the typeclass `is_localization.away x S` states that `S` is
isomorphic to the localization of `R` at the submonoid generated by `x`. -/
abbreviation away (S : Type*) [comm_semiring S] [algebra R S] :=
is_localization (submonoid.powers x) S

namespace away

variables [is_localization.away x S]

/-- Given `x : R` and a localization map `F : R →+* S` away from `x`, `inv_self` is `(F x)⁻¹`. -/
noncomputable def inv_self : S :=
mk' S (1 : R) ⟨x, submonoid.mem_powers _⟩

@[simp] lemma mul_inv_self : algebra_map R S x * inv_self x = 1 :=
by { convert is_localization.mk'_mul_mk'_eq_one _ 1, symmetry, apply is_localization.mk'_one }

variables {g : R →+* P}

/-- Given `x : R`, a localization map `F : R →+* S` away from `x`, and a map of `comm_semiring`s
`g : R →+* P` such that `g x` is invertible, the homomorphism induced from `S` to `P` sending
`z : S` to `g y * (g x)⁻ⁿ`, where `y : R, n : ℕ` are such that `z = F y * (F x)⁻ⁿ`. -/
noncomputable def lift (hg : is_unit (g x)) : S →+* P :=
is_localization.lift $ λ (y : submonoid.powers x), show is_unit (g y.1),
begin
  obtain ⟨n, hn⟩ := y.2,
  rw [←hn, g.map_pow],
  exact is_unit.map (pow_monoid_hom n : P →* P) hg,
end

@[simp] lemma away_map.lift_eq (hg : is_unit (g x)) (a : R) :
  lift x hg ((algebra_map R S) a) = g a := lift_eq _ _

@[simp] lemma away_map.lift_comp (hg : is_unit (g x)) :
  (lift x hg).comp (algebra_map R S) = g := lift_comp _

/-- Given `x y : R` and localizations `S`, `P` away from `x` and `x * y`
respectively, the homomorphism induced from `S` to `P`. -/
noncomputable def away_to_away_right (y : R) [algebra R P] [is_localization.away (x * y) P] :
  S →+* P :=
lift x $ show is_unit ((algebra_map R P) x), from
is_unit_of_mul_eq_one ((algebra_map R P) x) (mk' P y ⟨x * y, submonoid.mem_powers _⟩) $
by rw [mul_mk'_eq_mk'_of_mul, mk'_self]

variables (S) (Q : Type*) [comm_semiring Q] [algebra P Q]

/-- Given a map `f : R →+* S` and an element `r : R`, we may construct a map `Rᵣ →+* Sᵣ`. -/
noncomputable
def map (f : R →+* P) (r : R) [is_localization.away r S]
  [is_localization.away (f r) Q] : S →+* Q :=
is_localization.map Q f
  (show submonoid.powers r ≤ (submonoid.powers (f r)).comap f,
    by { rintros x ⟨n, rfl⟩, use n, simp })

end away

end away

variables [is_localization M S]

section at_units
variables (R) (S) (M)

/-- The localization at a module of units is isomorphic to the ring -/
noncomputable
def at_units (H : ∀ x : M, is_unit (x : R)) : R ≃ₐ[R] S :=
begin
  refine alg_equiv.of_bijective (algebra.of_id R S) ⟨_, _⟩,
  { intros x y hxy,
    obtain ⟨c, eq⟩ := (is_localization.eq_iff_exists M S).mp hxy,
    obtain ⟨u, hu⟩ := H c,
    rwa [← hu, units.mul_left_inj] at eq },
  { intros y,
    obtain ⟨⟨x, s⟩, eq⟩ := is_localization.surj M y,
    obtain ⟨u, hu⟩ := H s,
    use x * u.inv,
    dsimp only [algebra.of_id, ring_hom.to_fun_eq_coe, alg_hom.coe_mk],
    rw [ring_hom.map_mul, ← eq, ← hu, mul_assoc, ← ring_hom.map_mul],
    simp }
end

/-- The localization away from a unit is isomorphic to the ring -/
noncomputable
def at_unit (x : R) (e : is_unit x) [is_localization.away x S] : R ≃ₐ[R] S :=
begin
  apply at_units R (submonoid.powers x),
  rintros ⟨xn, n, hxn⟩,
  obtain ⟨u, hu⟩ := e,
  rw is_unit_iff_exists_inv,
  use u.inv ^ n,
  simp[← hxn, ← hu, ← mul_pow]
end

/-- The localization at one is isomorphic to the ring. -/
noncomputable
def at_one [is_localization.away (1 : R) S] : R ≃ₐ[R] S :=
@at_unit R _ S _ _ (1 : R) is_unit_one _

lemma away_of_is_unit_of_bijective {R : Type*} (S : Type*) [comm_ring R] [comm_ring S]
  [algebra R S] {r : R} (hr : is_unit r) (H : function.bijective (algebra_map R S)) :
  is_localization.away r S :=
{ map_units := by { rintros ⟨_, n, rfl⟩, exact (algebra_map R S).is_unit_map (hr.pow _) },
  surj := λ z, by { obtain ⟨z', rfl⟩ := H.2 z, exact ⟨⟨z', 1⟩, by simp⟩ },
  eq_iff_exists := λ x y, begin
    erw H.1.eq_iff,
    split,
    { rintro rfl, exact ⟨1, rfl⟩ },
    { rintro ⟨⟨_, n, rfl⟩, e⟩, exact (hr.pow _).mul_left_inj.mp e }
  end }

end at_units

end is_localization

namespace localization

open is_localization

variables {M}

/-- Given a map `f : R →+* S` and an element `r : R`, such that `f r` is invertible,
  we may construct a map `Rᵣ →+* S`. -/
noncomputable
abbreviation away_lift (f : R →+* P) (r : R) (hr : is_unit (f r)) :
  localization.away r →+* P :=
is_localization.away.lift r hr

/-- Given a map `f : R →+* S` and an element `r : R`, we may construct a map `Rᵣ →+* Sᵣ`. -/
noncomputable
abbreviation away_map (f : R →+* P) (r : R) :
  localization.away r →+* localization.away (f r) :=
is_localization.away.map _ _ f r

end localization

end comm_semiring

open polynomial adjoin_root localization

variables {R : Type*} [comm_ring R]

local attribute [instance] is_localization.alg_hom_subsingleton adjoin_root.alg_hom_subsingleton

/-- The `R`-`alg_equiv` between the localization of `R` away from `r` and
    `R` with an inverse of `r` adjoined. -/
noncomputable def localization.away_equiv_adjoin (r : R) : away r ≃ₐ[R] adjoin_root (C r * X - 1) :=
alg_equiv.of_alg_hom
  { commutes' := is_localization.away.away_map.lift_eq r
      (is_unit_of_mul_eq_one _ _ $ root_is_inv r), .. away_lift _ r _ }
  (lift_hom _ (is_localization.away.inv_self r) $ by simp only
    [map_sub, map_mul, aeval_C, aeval_X, is_localization.away.mul_inv_self, aeval_one, sub_self])
  (subsingleton.elim _ _)
  (subsingleton.elim _ _)

lemma is_localization.adjoin_inv (r : R) : is_localization.away r (adjoin_root $ C r * X - 1) :=
is_localization.is_localization_of_alg_equiv _ (localization.away_equiv_adjoin r)

lemma is_localization.away.finite_presentation (r : R) {S} [comm_ring S] [algebra R S]
  [is_localization.away r S] : algebra.finite_presentation R S :=
(adjoin_root.finite_presentation _).equiv $ (localization.away_equiv_adjoin r).symm.trans $
  is_localization.alg_equiv (submonoid.powers r) _ _
