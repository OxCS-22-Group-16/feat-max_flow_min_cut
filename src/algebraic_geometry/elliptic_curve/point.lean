/-
Copyright (c) 2022 David Kurniadi Angdinata. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Kurniadi Angdinata
-/

import algebraic_geometry.elliptic_curve.weierstrass
import field_theory.galois -- temporary import to enable point notation
import ring_theory.class_group

/-!
# The group of nonsingular rational points on a Weierstrass curve over a field

This file defines the type of nonsingular rational points on a Weierstrass curve over a field and
(TODO) proves that it forms an abelian group under a secant-and-tangent process.

## Mathematical background

Let `W` be an Weierstrass curve over a field `F`. A rational point on `W` is simply a point
$[A:B:C]$ defined over `F` in the projective plane satisfying the homogeneous cubic equation
$B^2C + a_1ABC + a_3BC^2 = A^3 + a_2A^2C + a_4AC^2 + a_6C^3$. Any such point either lies in the
affine chart $C \ne 0$ and satisfies the Weierstrass equation obtained by setting $X := A/C$ and
$Y := B/C$, or is the unique point at infinity $0 := [0:1:0]$ when $C = 0$. With this new
description, a nonsingular rational point on `W` is either $\mathcal{O}$ or an affine point $(x, y)$
where the partial derivatives $W_X(X, Y)$ and $W_Y(X, Y)$ do not both vanish. For a field extension
`K` of `F`, a `K`-rational point is simply a rational point on `W` base changed to `K`.

The set of nonsingular rational points forms an abelian group under a secant-and-tangent process.
 * The identity point is `0`.
 * Given a point `P`, its negation `-P` is defined to be the unique third point of intersection
    between `W` and the line through `0` and `P`, which exists by Bézout's theorem.
    Explicitly, if `P` is $(x, y)$, then `-P` is $(x, -y - a_1x - a_3)$.
 * Given two points `P` and `Q`, their addition `P + Q` is defined to be the negation of the unique
    third point of intersection between `W` and the line through `P` and `Q`, which again exists by
    Bézout's theorem. Explicitly, let `P` be $(x_1, y_1)$ and let `Q` be $(x_2, y_2)$.
      * If $x_1 = x_2$ and `P = -Q`, then this line is vertical and `P + Q` is `0`.
      * If $x_1 = x_2$ and `P ≠ -Q`, then this line is the tangent of `W` at `P = Q`, and has slope
        $\ell := (3x_1^2 + 2a_2x_1 + a_4 - a_1y_1) / (2y_1 + a_1x_1 + a_3)$.
      * Otherwise $x_1 \ne x_2$ then this line is the secant of `W` through `P` and `Q`, and has
        slope $\ell := (y_1 - y_2) / (x_1 - x_2)$.
    In the latter two cases, the $X$-coordinate of `P + Q` is then the unique third solution of the
    equation obtained by substituting the line $Y = \ell(X - x_1) + y_1$ into the Weierstrass
    equation, and can be written down explicitly as $x := \ell^2 + a_1\ell - a_2 - x_1 - x_2$ by
    inspecting the $X^2$ terms. The $Y$-coordinate of `P + Q`, after applying the final negation
    that maps $Y$ to $-Y - a_1X - a_3$, is precisely $y := -(\ell(x - x_1) + y_1) - x - a_3$.
The group law on this set is then uniquely determined by these constructions.

## Main definitions

 * `weierstrass_curve.point`: the type of nonsingular rational points on a Weierstrass curve `W`.
 * `weierstrass_curve.point.add`: the addition of two nonsingular rational points on `W`.

## Main statements

 * TODO: the addition of two nonsingular rational points on `W` forms a group.

## Notations

 * `W⟮K⟯`: the group of nonsingular rational points on a Weierstrass curve `W` base changed to `K`.

## References

[J Silverman, *The Arithmetic of Elliptic Curves*][silverman2009]

## Tags

elliptic curve, rational point, group law
-/

private meta def eval_simp : tactic unit :=
`[simp only [eval_C, eval_X, eval_neg, eval_add, eval_sub, eval_mul, eval_pow]]

private meta def C_simp : tactic unit :=
`[simp only [C_1, C_bit0, C_bit1, C_neg, C_add, C_sub, C_mul, C_pow]]

private meta def derivative_simp : tactic unit :=
`[simp only [derivative_C, derivative_X, derivative_X_pow, derivative_neg, derivative_add,
             derivative_sub, derivative_mul, derivative_sq]]

universe u

namespace weierstrass_curve

open polynomial

open_locale non_zero_divisors polynomial

section basic

/-! ### Polynomials associated to nonsingular rational points on a Weierstrass curve -/

variables {R : Type u} [comm_ring R] (W : weierstrass_curve R) (x₁ x₂ y₁ y₂ L : R)

/-- The ideal $\langle X - x_1, Y - y_1 \rangle$ of $F[W]$ for some $x_1, y_1 \in F$. -/
@[simp] noncomputable def XY_ideal : ideal W.coordinate_ring :=
ideal.span {W.X_class x₁, W.Y_class $ C y₁}

/-- The polynomial $-Y - a_1X - a_3$ associated to negation. -/
noncomputable def neg_polynomial : R[X][X] := -X - C (C W.a₁ * X + C W.a₃)

lemma Y_add_neg_polynomial : X + W.neg_polynomial = -C (C W.a₁ * X + C W.a₃) :=
by { rw [neg_polynomial], ring1 }

lemma Y_sub_neg_polynomial : X - W.neg_polynomial = W.polynomial_Y :=
by { rw [neg_polynomial, polynomial_Y], C_simp, ring1 }

lemma Y_mul_neg_polynomial :
  X * W.neg_polynomial = -C (X ^ 3 + C W.a₂ * X ^ 2 + C W.a₄ * X + C W.a₆) - W.polynomial :=
by { rw [neg_polynomial, weierstrass_curve.polynomial], ring1 }

lemma coordinate_ring.Y_mul_neg_polynomial :
  adjoin_root.mk W.polynomial (X * W.neg_polynomial)
    = adjoin_root.mk W.polynomial (-C (X ^ 3 + C W.a₂ * X ^ 2 + C W.a₄ * X + C W.a₆)) :=
adjoin_root.mk_eq_mk.mpr ⟨-1, by rw [Y_mul_neg_polynomial, sub_sub_cancel_left, mul_neg_one]⟩

/-- The $Y$-coordinate of the negation of an affine point.

This depends on `W`, and has argument order: $x_1$, $y_1$. -/
@[simp] def neg_Y : R := -y₁ - W.a₁ * x₁ - W.a₃

lemma neg_Y_neg_Y : -W.neg_Y x₁ y₁ - W.a₁ * x₁ - W.a₃ = y₁ := by { rw [neg_Y], ring1 }

@[simp] lemma eval_neg_polynomial : eval x₁ (eval (C y₁) W.neg_polynomial) = W.neg_Y x₁ y₁ :=
by { rw [neg_Y, sub_sub, neg_polynomial], eval_simp }

/-- A sloped line through two affine points $(x_1, y_1)$ and $(x_2, y_2)$ in `W`.
If $x_1 \ne x_2$, then this line is the secant of `W` through $(x_1, y_1)$ and $(x_2, y_2)$.
Otherwise, if $y_1 \ne -y_1 - a_1x_1 - a_3$, then this line is the tangent of `W` at
$(x_1, y_1) = (x_2, y_2)$. Otherwise, this line is vertical and its slope is not well-defined.

This depends on `W`, and has argument order: $x_1$, $x_2$, $y_1$, $y_2$. -/
inductive line
| eq (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂)
| ne (hx : x₁ ≠ x₂)

instance : inhabited $ (default : weierstrass_curve ℚ).line 1 0 0 0 := ⟨line.ne one_ne_zero⟩

/-- The polynomial $L*(X - x_1) + y_1$ associated to the line $Y = L*(X - x_1) + y_1$,
with a slope of $L$ that passes through an affine point $(x_1, y_1)$.

This does not depend on `W`, and has argument order: $x_1$, $y_1$, $L$. -/
noncomputable def line_polynomial : R[X] := C L * (X - C x₁) + C y₁

@[simp] lemma eval_line_polynomial : eval x₁ (line_polynomial x₁ y₁ L) = y₁ :=
by { rw [line_polynomial], eval_simp, rw [sub_self, mul_zero, zero_add] }

/-- The polynomial obtained by substituting the line $Y = L*(X - x_1) + y_1$, with a slope of $L$
that passes through an affine point $(x_1, y_1)$, into the polynomial $W(X, Y)$ associated to `W`.
If such a line intersects `W` at a point $(x_2, y_2)$ of `W`, then the roots of this polynomial are
precisely $x_1$, $x_2$, and the $X$-coordinate of the addition of $(x_1, y_1)$ and $(x_2, y_2)$.

This depends on `W`, and has argument order: $x_1$, $y_1$, $L$. -/
noncomputable def add_polynomial : R[X] := eval (line_polynomial x₁ y₁ L) W.polynomial

lemma C_add_polynomial :
  C (W.add_polynomial x₁ y₁ L)
    = (X - C (line_polynomial x₁ y₁ L)) * (W.neg_polynomial - C (line_polynomial x₁ y₁ L))
      + W.polynomial :=
by { rw [add_polynomial, line_polynomial, weierstrass_curve.polynomial, neg_polynomial], eval_simp,
     C_simp, ring1 }

lemma coordinate_ring.C_add_polynomial :
  adjoin_root.mk W.polynomial (C (W.add_polynomial x₁ y₁ L))
    = adjoin_root.mk W.polynomial
      ((X - C (line_polynomial x₁ y₁ L)) * (W.neg_polynomial - C (line_polynomial x₁ y₁ L))) :=
adjoin_root.mk_eq_mk.mpr ⟨1, by rw [C_add_polynomial, add_sub_cancel', mul_one]⟩

lemma add_polynomial_eq : W.add_polynomial x₁ y₁ L = -cubic.to_poly
  ⟨1, -L ^ 2 - W.a₁ * L + W.a₂,
    2 * x₁ * L ^ 2 + (W.a₁ * x₁ - 2 * y₁ - W.a₃) * L + (-W.a₁ * y₁ + W.a₄),
    -x₁ ^ 2 * L ^ 2 + (2 * x₁ * y₁ + W.a₃ * x₁) * L - (y₁ ^ 2 + W.a₃ * y₁ - W.a₆)⟩ :=
by { rw [add_polynomial, line_polynomial, weierstrass_curve.polynomial, cubic.to_poly], eval_simp,
     C_simp, ring1 }

/-- The $X$-coordinate of the addition of two affine points $(x_1, y_1)$ and $(x_2, y_2)$ in `W`,
where the line through them is not vertical and has a slope of $L$.

This depends on `W`, and has argument order: $x_1$, $x_2$, $L$. -/
@[simp] def add_X : R := L ^ 2 + W.a₁ * L - W.a₂ - x₁ - x₂

/-- The $Y$-coordinate, before applying the final negation, of the addition of two affine points
$(x_1, y_1)$ and $(x_2, y_2)$, where the line through them is not vertical and has a slope of $L$.

This depends on `W`, and has argument order: $x_1$, $x_2$, $y_1$, $L$. -/
@[simp] def add_Y' : R := L * (W.add_X x₁ x₂ L - x₁) + y₁

lemma eval_add_line_polynomial :
  eval (W.add_X x₁ x₂ L) (line_polynomial x₁ y₁ L) = W.add_Y' x₁ x₂ y₁ L :=
by { rw [add_Y', line_polynomial], eval_simp }

/-- The $Y$-coordinate of the addition of two affine points $(x_1, y_1)$ and $(x_2, y_2)$ in `W`,
where the line through them is not vertical and has a slope of $L$.

This depends on `W`, and has argument order: $x_1$, $x_2$, $y_1$, $L$. -/
@[simp] def add_Y : R := -W.add_Y' x₁ x₂ y₁ L - W.a₁ * W.add_X x₁ x₂ L - W.a₃

lemma eval_add_neg_polynomial :
  eval (W.add_X x₁ x₂ L) (eval (C $ W.add_Y' x₁ x₂ y₁ L) W.neg_polynomial) = W.add_Y x₁ x₂ y₁ L :=
by { rw [add_Y, sub_sub, neg_polynomial], eval_simp }

lemma equation_add_iff :
  W.equation (W.add_X x₁ x₂ L) (W.add_Y' x₁ x₂ y₁ L)
    ↔ eval (W.add_X x₁ x₂ L) (W.add_polynomial x₁ y₁ L) = 0 :=
by { rw [equation, add_Y', add_polynomial, line_polynomial, weierstrass_curve.polynomial],
     eval_simp }

lemma nonsingular_add_of_eval_derivative_ne_zero
  (hx : eval (W.add_X x₁ x₂ L) (derivative $ W.add_polynomial x₁ y₁ L) ≠ 0) :
  W.nonsingular (W.add_X x₁ x₂ L) (W.add_Y' x₁ x₂ y₁ L) :=
begin
  rw [nonsingular, add_Y', polynomial_X, polynomial_Y],
  eval_simp,
  contrapose! hx,
  rw [add_polynomial, line_polynomial, weierstrass_curve.polynomial],
  eval_simp,
  derivative_simp,
  simp only [zero_add, add_zero, sub_zero, zero_mul, mul_one],
  eval_simp,
  linear_combination hx.left + L * hx.right with { normalization_tactic := `[norm_num1, ring1] }
end

/-! ### The type of nonsingular rational points on a Weierstrass curve -/

/-- A nonsingular rational point on a Weierstrass curve `W` over `R`. This is either the point at
infinity `weierstrass_curve.point.zero` or an affine point `weierstrass_curve.point.some` $(x, y)$
satisfying the equation $y^2 + a_1xy + a_3y = x^3 + a_2x^2 + a_4x + a_6$ of `W`. For an algebraic
extension `S` of `R`, the type of nonsingular `S`-rational points on `W` is denoted `W⟮S⟯`. -/
inductive point
| zero
| some {x y : R} (h : W.equation x y) (h' : W.nonsingular x y)

localized "notation W⟮K⟯ := (W.base_change K).point" in weierstrass_curve

namespace point

instance : inhabited W.point := ⟨zero⟩

instance : has_zero W.point := ⟨zero⟩

@[simp] lemma zero_def : (zero : W.point) = 0 := rfl

end point

variables {W x₁ y₁}

/-- The negation of an affine point in `W` lies in `W`. -/
lemma equation_neg (h : W.equation x₁ y₁) : W.equation x₁ $ W.neg_Y x₁ y₁ :=
by { rw [equation_iff] at h, rw [equation_iff, neg_Y, ← h], ring1 }

/-- The negation of a nonsingular affine point is nonsingular. -/
lemma nonsingular_neg (h' : W.nonsingular x₁ y₁) : W.nonsingular x₁ $ W.neg_Y x₁ y₁ :=
begin
  rw [nonsingular_iff] at h',
  rw [nonsingular_iff, neg_Y_neg_Y, ← @ne_comm _ y₁],
  contrapose! h',
  convert h',
  exact h'.right
end

namespace point

/-- The negation of a nonsingular rational point.

Given a nonsingular rational point `P`, use `-P` instead of `neg P`. -/
def neg : W.point → W.point
| 0           := 0
| (some h h') := some (equation_neg h) (nonsingular_neg h')

instance : has_neg W.point := ⟨neg⟩

@[simp] lemma neg_def (P : W.point) : P.neg = -P := rfl

@[simp] lemma neg_zero : (-0 : W.point) = 0 := rfl

@[simp] lemma neg_some (h : W.equation x₁ y₁) (h' : W.nonsingular x₁ y₁) :
  -some h h' = some (equation_neg h) (nonsingular_neg h') :=
rfl

instance : has_involutive_neg W.point := ⟨neg, by { rintro (_ | _), { refl }, { simp, ring1 } }⟩

end point

end basic

open line

section addition

/-! ### The addition law on nonsingular rational points on a Weierstrass curve -/

variables {F : Type u} [field F] {W : weierstrass_curve F} {x₁ x₂ y₁ y₂ : F}
  (h₁ : W.equation x₁ y₁) (h₂ : W.equation x₂ y₂)
  (h₁' : W.nonsingular x₁ y₁) (h₂' : W.nonsingular x₂ y₂) (L : W.line x₁ x₂ y₁ y₂)

/-- The slope of the sloped line through two affine points $(x_1, y_1)$ and $(x_2, y_2)$ in `W`.
If $x_1 \ne x_2$, then this line has slope $(y_1 - y_2) / (x_1 - x_2)$,
otherwise this line has slope $(3x_1^2 + 2a_2x_1 + a_4 - a_1y_1) / (2y_1 + a_1x_1 + a_3)$. -/
def slope : W.line x₁ x₂ y₁ y₂ → F
| (eq _ _) := (3 * x₁ ^ 2 + 2 * W.a₂ * x₁ + W.a₄ - W.a₁ * y₁) / (y₁ - W.neg_Y x₁ y₁)
| (ne _)   := (y₁ - y₂) / (x₁ - x₂)

@[simp] lemma slope_eq (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂) :
  slope (eq hx hy) = (3 * x₁ ^ 2 + 2 * W.a₂ * x₁ + W.a₄ - W.a₁ * y₁) / (y₁ - W.neg_Y x₁ y₁) :=
rfl

@[simp] lemma slope_eq_self (hy : y₁ ≠ W.neg_Y x₁ y₁) :
  slope (eq rfl hy) = (3 * x₁ ^ 2 + 2 * W.a₂ * x₁ + W.a₄ - W.a₁ * y₁) / (y₁ - W.neg_Y x₁ y₁) :=
rfl

@[simp] lemma slope_ne (hx : x₁ ≠ x₂) :
  slope (ne hx : W.line x₁ x₂ y₁ y₂) = (y₁ - y₂) / (x₁ - x₂) :=
rfl

lemma slope_eq_eq_eval (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂) :
  slope (eq hx hy) = -eval x₁ (eval (C y₁) W.polynomial_X) / eval x₁ (eval (C y₁) W.polynomial_Y) :=
by { rw [slope_eq, eval_polynomial_X, neg_sub], congr' 1, rw [neg_Y, eval_polynomial_Y], ring1 }

include h₁ h₂

lemma Y_eq_of_X_eq (hx : x₁ = x₂) : y₁ = y₂ ∨ y₁ = W.neg_Y x₂ y₂ :=
begin
  rw [equation_iff] at h₁ h₂,
  rw [← sub_eq_zero, ← @sub_eq_zero _ _ y₁, ← mul_eq_zero, neg_Y],
  linear_combination h₁ - h₂ with { normalization_tactic := `[rw [hx], ring1] }
end

lemma Y_eq_of_Y_ne (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂) : y₁ = y₂ :=
or.resolve_right (Y_eq_of_X_eq h₁ h₂ hx) hy

lemma eval_line_polynomial' : eval x₂ (line_polynomial x₁ y₁ $ slope L) = y₂ :=
begin
  rcases L with ⟨rfl, hy⟩ | hx,
  { rcases Y_eq_of_Y_ne h₁ h₂ rfl hy with rfl,
    field_simp [line_polynomial, sub_ne_zero_of_ne hy] },
  { field_simp [line_polynomial, sub_ne_zero_of_ne hx],
    ring1 }
end

lemma add_polynomial_slope :
  W.add_polynomial x₁ y₁ (slope L)
    = -((X - C x₁) * (X - C x₂) * (X - C (W.add_X x₁ x₂ $ slope L))) :=
begin
  rw [add_polynomial_eq, neg_inj, cubic.prod_X_sub_C_eq, cubic.to_poly_injective],
  rcases L with ⟨rfl, hy⟩ | hx,
  any_goals { rcases Y_eq_of_Y_ne h₁ h₂ rfl hy with rfl },
  all_goals { rw [equation_iff] at h₁ h₂ },
  { rw [neg_Y, ← sub_ne_zero] at hy,
    ext,
    { refl },
    { simp only [add_X],
      ring1 },
    { field_simp [hy],
      ring1 },
    { linear_combination -h₁ with { normalization_tactic := `[field_simp [hy], ring1] } } },
  { rw [← sub_ne_zero] at hx,
    ext,
    { refl },
    { simp only [add_X],
      ring1 },
    { apply mul_right_injective₀ hx,
      linear_combination h₂ - h₁ with { normalization_tactic := `[field_simp [hx], ring1] } },
    { apply mul_right_injective₀ hx,
      linear_combination x₂ * h₁ - x₁ * h₂
        with { normalization_tactic := `[field_simp [hx], ring1] } } }
end

lemma coordinate_ring.C_add_polynomial_slope :
  adjoin_root.mk W.polynomial (C $ W.add_polynomial x₁ y₁ $ slope L)
    = -(W.X_class x₁ * W.X_class x₂ * W.X_class (W.add_X x₁ x₂ $ slope L)) :=
by simpa only [add_polynomial_slope h₁ h₂ L, map_neg, neg_inj, map_mul]

lemma derivative_add_polynomial_slope :
  derivative (W.add_polynomial x₁ y₁ $ slope L)
    = -((X - C x₁) * (X - C x₂) + (X - C x₁) * (X - C (W.add_X x₁ x₂ $ slope L))
        + (X - C x₂) * (X - C (W.add_X x₁ x₂ $ slope L))) :=
by { rw [add_polynomial_slope h₁ h₂], derivative_simp, ring1 }

/-- The addition of two affine points in `W` on a sloped line,
before applying the final negation that maps $Y$ to $-Y - a_1X - a_3$, lies in `W`. -/
lemma equation_add' : W.equation (W.add_X x₁ x₂ $ slope L) (W.add_Y' x₁ x₂ y₁ $ slope L) :=
by { rw [equation_add_iff, add_polynomial_slope h₁ h₂], eval_simp,
     rw [neg_eq_zero, sub_self, mul_zero] }

/-- The addition of two affine points in `W` on a sloped line lies in `W`. -/
lemma equation_add : W.equation (W.add_X x₁ x₂ $ slope L) (W.add_Y x₁ x₂ y₁ $ slope L) :=
equation_neg $ equation_add' h₁ h₂ L

include h₁' h₂'

/-- The addition of two nonsingular affine points in `W` on a sloped line,
before applying the final negation that maps $Y$ to $-Y - a_1X - a_3$, is nonsingular. -/
lemma nonsingular_add' : W.nonsingular (W.add_X x₁ x₂ $ slope L) (W.add_Y' x₁ x₂ y₁ $ slope L) :=
begin
  by_cases hx₁ : W.add_X x₁ x₂ (slope L) = x₁,
  { rwa [add_Y', hx₁, sub_self, mul_zero, zero_add] },
  { by_cases hx₂ : W.add_X x₁ x₂ (slope L) = x₂,
    { rcases L with ⟨rfl, hy⟩ | hx,
      { contradiction },
      { rwa [add_Y', ← neg_sub, mul_neg, hx₂, slope_ne, div_mul_cancel _ $ sub_ne_zero_of_ne hx,
             neg_sub, sub_add_cancel] } },
    { apply nonsingular_add_of_eval_derivative_ne_zero,
      rw [derivative_add_polynomial_slope h₁ h₂],
      eval_simp,
      simpa only [neg_ne_zero, sub_self, mul_zero, add_zero]
        using mul_ne_zero (sub_ne_zero_of_ne hx₁) (sub_ne_zero_of_ne hx₂) } }
end

/-- The addition of two nonsingular affine points in `W` on a sloped line is nonsingular. -/
lemma nonsingular_add : W.nonsingular (W.add_X x₁ x₂ $ slope L) (W.add_Y x₁ x₂ y₁ $ slope L) :=
nonsingular_neg $ nonsingular_add' h₁ h₂ h₁' h₂' L

omit h₁ h₂ h₁' h₂'

namespace point

open_locale classical

/-- The addition of two nonsingular rational points.

Given two nonsingular rational points `P` and `Q`, use `P + Q` instead of `add P Q`. -/
noncomputable def add : W.point → W.point → W.point
| 0                          P                          := P
| P                          0                          := P
| (@some _ _ _ x₁ y₁ h₁ h₁') (@some _ _ _ x₂ y₂ h₂ h₂') :=
if hx : x₁ = x₂ then if hy : y₁ = W.neg_Y x₂ y₂ then 0
else some (equation_add h₁ h₂ $ eq hx hy) (nonsingular_add h₁ h₂ h₁' h₂' $ eq hx hy)
else some (equation_add h₁ h₂ $ ne hx) (nonsingular_add h₁ h₂ h₁' h₂' $ ne hx)

noncomputable instance : has_add W.point := ⟨add⟩

@[simp] lemma add_def (P Q : W.point) : P.add Q = P + Q := rfl

noncomputable instance : add_zero_class W.point :=
⟨0, (+), by rintro (_ | _); refl, by rintro (_ | _); refl⟩

@[simp] lemma some_add_some_of_Y_eq (hx : x₁ = x₂) (hy : y₁ = W.neg_Y x₂ y₂) :
  some h₁ h₁' + some h₂ h₂' = 0 :=
by rw [← add_def, add, dif_pos hx, dif_pos hy]

@[simp] lemma some_add_self_of_Y_eq (hy : y₁ = W.neg_Y x₁ y₁) : some h₁ h₁' + some h₁ h₁' = 0 :=
some_add_some_of_Y_eq h₁ h₁ h₁' h₁' rfl hy

@[simp] lemma some_add_some_of_Y_ne (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂) :
  some h₁ h₁' + some h₂ h₂'
    = some (equation_add h₁ h₂ $ eq hx hy) (nonsingular_add h₁ h₂ h₁' h₂' $ eq hx hy) :=
by rw [← add_def, add, dif_pos hx, dif_neg hy]

lemma some_add_some_of_Y_ne' (hx : x₁ = x₂) (hy : y₁ ≠ W.neg_Y x₂ y₂) :
  some h₁ h₁' + some h₂ h₂'
    = -some (equation_add' h₁ h₂ $ eq hx hy) (nonsingular_add' h₁ h₂ h₁' h₂' $ eq hx hy) :=
some_add_some_of_Y_ne h₁ h₂ h₁' h₂' hx hy

@[simp] lemma some_add_self_of_Y_ne (hy : y₁ ≠ W.neg_Y x₁ y₁) :
  some h₁ h₁' + some h₁ h₁'
    = some (equation_add h₁ h₁ $ eq rfl hy) (nonsingular_add h₁ h₁ h₁' h₁' $ eq rfl hy) :=
some_add_some_of_Y_ne h₁ h₁ h₁' h₁' rfl hy

lemma some_add_self_of_Y_ne' (hy : y₁ ≠ W.neg_Y x₁ y₁) :
  some h₁ h₁' + some h₁ h₁'
    = -some (equation_add' h₁ h₁ $ eq rfl hy) (nonsingular_add' h₁ h₁ h₁' h₁' $ eq rfl hy) :=
some_add_some_of_Y_ne h₁ h₁ h₁' h₁' rfl hy

@[simp] lemma some_add_some_of_X_ne (hx : x₁ ≠ x₂) :
  some h₁ h₁' + some h₂ h₂'
    = some (equation_add h₁ h₂ $ ne hx) (nonsingular_add h₁ h₂ h₁' h₂' $ ne hx) :=
by rw [← add_def, add, dif_neg hx]

lemma some_add_some_of_X_ne' (hx : x₁ ≠ x₂) :
  some h₁ h₁' + some h₂ h₂'
    = -some (equation_add' h₁ h₂ $ ne hx) (nonsingular_add' h₁ h₂ h₁' h₂' $ ne hx) :=
some_add_some_of_X_ne h₁ h₂ h₁' h₂' hx

end point

/-! ### The axioms for nonsingular rational points on a Weierstrass curve -/

include h₁

private lemma XY_ideal_neg_mul_XY_ideal_aux :
  (X - C (C y₁)) * (X - C (C (W.neg_Y x₁ y₁))) - C (X - C x₁)
    * (C (X ^ 2 + C (W.a₂ + x₁) * X + C (x₁ ^ 2 + W.a₂ * x₁ + W.a₄)) - C (C W.a₁) * X)
    = W.polynomial * 1 :=
by linear_combination congr_arg C (congr_arg C ((W.equation_iff _ _).mp h₁).symm)
   with { normalization_tactic := `[rw [neg_Y, weierstrass_curve.polynomial], C_simp, ring1] }

omit h₁

include h₁'

private lemma XY_ideal_neg_mul_XY_ideal_aux' :
  ∃ a b c d,
    d * (C (X ^ 2 + C (W.a₂ + x₁) * X + C (x₁ ^ 2 + W.a₂ * x₁ + W.a₄)) - C (C W.a₁) * X)
      = 1 + a * C (X - C x₁) + b * (X - C (C y₁)) + c * (X - C (C (W.neg_Y x₁ y₁))) :=
begin
  cases (W.nonsingular_iff' _ _).mp h₁' with hx hy,
  { set W_X := W.a₁ * y₁ - (3 * x₁ ^ 2 + 2 * W.a₂ * x₁ + W.a₄),
    refine ⟨C (C W_X⁻¹ * -(X + C (2 * x₁ + W.a₂))), C (C $ W_X⁻¹ * W.a₁), 0, C (C $ W_X⁻¹ * -1), _⟩,
    rw [← mul_right_inj' $ C_ne_zero.mpr $ C_ne_zero.mpr hx],
    simp only [← mul_assoc, mul_add, ← C_mul, mul_inv_cancel hx],
    C_simp,
    ring1 },
  { set W_Y := 2 * y₁ + W.a₁ * x₁ + W.a₃,
    refine ⟨0, C (C W_Y⁻¹), C (C $ W_Y⁻¹ * -1), 0, _⟩,
    rw [neg_Y, ← mul_right_inj' $ C_ne_zero.mpr $ C_ne_zero.mpr hy],
    simp only [← mul_assoc, mul_add, ← C_mul, mul_inv_cancel hy],
    C_simp,
    ring1 }
end

include h₁

lemma XY_ideal_neg_mul_XY_ideal : W.XY_ideal x₁ (W.neg_Y x₁ y₁) * W.XY_ideal x₁ y₁ = W.X_ideal x₁ :=
begin
  simp_rw [XY_ideal, Y_class, ideal.span_insert, ideal.sup_mul, ideal.mul_sup, ← sup_assoc,
           mul_comm],
  conv_lhs { congr, skip, rw [ideal.span_singleton_mul_span_singleton, ← map_mul,
                              adjoin_root.mk_eq_mk.mpr ⟨1, XY_ideal_neg_mul_XY_ideal_aux h₁⟩,
                              map_mul, ← ideal.span_singleton_mul_span_singleton] },
  simp_rw [X_ideal, X_class, ← @set.image_singleton _ _ $ adjoin_root.mk _, ← ideal.map_span,
           ← ideal.mul_sup, ← ideal.map_sup, sup_assoc, ← ideal.span_insert],
  convert ideal.mul_top _ using 2,
  convert ideal.map_top (adjoin_root.mk W.polynomial) using 1,
  apply congr_arg (ideal.map _),
  simp only [ideal.eq_top_iff_one, ideal.mem_span_insert', ideal.mem_span_singleton'],
  exact XY_ideal_neg_mul_XY_ideal_aux' h₁'
end

lemma XY_ideal_neg_mul_X_ideal_inv_mul_XY_ideal :
  (W.XY_ideal x₁ (W.neg_Y x₁ y₁) * (W.X_ideal x₁)⁻¹
    : fractional_ideal W.coordinate_ring⁰ W.function_field) * W.XY_ideal x₁ y₁ = 1 :=
by rw [mul_assoc, mul_comm _⁻¹, ← mul_assoc, ← fractional_ideal.coe_ideal_mul,
       XY_ideal_neg_mul_XY_ideal h₁ h₁', X_ideal,
       fractional_ideal.coe_ideal_span_singleton_mul_inv W.function_field $ W.X_class_ne_zero x₁]

omit h₁ h₁'

/-- The non-zero fractional ideal $\langle X - x, Y - y \rangle$ of $F(W)$ for some $x, y \in F$. -/
@[simps] noncomputable def XY_ideal' : (fractional_ideal W.coordinate_ring⁰ W.function_field)ˣ :=
⟨_, _, by rw [mul_comm, XY_ideal_neg_mul_X_ideal_inv_mul_XY_ideal h₁ h₁'],
  XY_ideal_neg_mul_X_ideal_inv_mul_XY_ideal h₁ h₁'⟩

lemma XY_ideal'_eq :
  (XY_ideal' h₁ h₁' : fractional_ideal W.coordinate_ring⁰ W.function_field) = W.XY_ideal x₁ y₁ :=
rfl

lemma XY_ideal'_neg_mul_XY_ideal' :
  (↑(XY_ideal' (equation_neg h₁) (nonsingular_neg h₁') * XY_ideal' h₁ h₁')
    : fractional_ideal W.coordinate_ring⁰ W.function_field) = W.X_ideal x₁ :=
by rw [units.coe_mul, XY_ideal'_eq, XY_ideal'_eq, ← fractional_ideal.coe_ideal_mul,
       fractional_ideal.coe_ideal_inj, XY_ideal_neg_mul_XY_ideal h₁ h₁']

local attribute [irreducible] coordinate_ring.comm_ring

lemma mk_XY_ideal'_mul_mk_XY_ideal'_of_Y_eq (hx : x₁ = x₂) (hy : y₁ = W.neg_Y x₂ y₂) :
  class_group.mk (XY_ideal' h₁ h₁') * class_group.mk (XY_ideal' h₂ h₂') = 1 :=
by simpa only [hx, hy, ← map_mul]
   using (class_group.mk_eq_one_of_coe_ideal $ XY_ideal'_neg_mul_XY_ideal' h₂ h₂').mpr
          ⟨W.X_class x₂, W.X_class_ne_zero x₂, rfl⟩

lemma mk_XY_ideal'_mul_mk_XY_ideal' :
  class_group.mk (XY_ideal' h₁ h₁') * class_group.mk (XY_ideal' h₂ h₂')
    = class_group.mk (XY_ideal' (equation_add h₁ h₂ L) (nonsingular_add h₁ h₂ h₁' h₂' L)) :=
sorry

namespace point

/-- The set function mapping an affine point $(x, y)$ of `W` to the class of the non-zero fractional
ideal $\langle X - x, Y - y \rangle$ of $F(W)$ in the class group of $F[W]$. -/
@[simp] noncomputable def to_class_fun : W.point → additive (class_group W.coordinate_ring)
| 0           := 0
| (some h h') := class_group.mk $ XY_ideal' h h'

/-- The group homomorphism mapping an affine point $(x, y)$ of `W` to the class of the non-zero
fractional ideal $\langle X - x, Y - y \rangle$ of $F(W)$ in the class group of $F[W]$. -/
@[simps] noncomputable def to_class : W.point →+ additive (class_group W.coordinate_ring) :=
{ to_fun    := to_class_fun,
  map_zero' := rfl,
  map_add'  :=
  begin
    rintro (_ | @⟨x₁, y₁, h₁, h₁'⟩) (_ | @⟨x₂, y₂, h₂, h₂'⟩),
    any_goals { simp only [zero_def, to_class_fun, _root_.zero_add, _root_.add_zero] },
    by_cases hx : x₁ = x₂,
    { by_cases hy : y₁ = W.neg_Y x₂ y₂,
      { simpa only [some_add_some_of_Y_eq h₁ h₂ h₁' h₂' hx hy]
          using (mk_XY_ideal'_mul_mk_XY_ideal'_of_Y_eq h₁ h₂ h₁' h₂' hx hy).symm },
      { simpa only [some_add_some_of_Y_ne h₁ h₂ h₁' h₂' hx hy]
          using (mk_XY_ideal'_mul_mk_XY_ideal' h₁ h₂ h₁' h₂' $ eq hx hy).symm } },
    { simpa only [some_add_some_of_X_ne h₁ h₂ h₁' h₂' hx]
        using (mk_XY_ideal'_mul_mk_XY_ideal' h₁ h₂ h₁' h₂' $ ne hx).symm }
  end }

@[simp] lemma to_class_zero : to_class (0 : W.point) = 0 := rfl

@[simp] lemma to_class_some : to_class (some h₁ h₁') = class_group.mk (XY_ideal' h₁ h₁') := rfl

@[simp] lemma add_eq_zero (P Q : W.point) : P + Q = 0 ↔ P = -Q :=
begin
  rcases ⟨P, Q⟩ with ⟨_ | @⟨x₁, y₁, h₁, h₁'⟩, _ | @⟨x₂, y₂, h₂, h₂'⟩⟩,
  any_goals { refl },
  { rw [zero_def, zero_add, eq_neg_iff_eq_neg, neg_zero] },
  { simp only [neg_some],
    split,
    { intro h,
      by_cases hx : x₁ = x₂,
      { by_cases hy : y₁ = W.neg_Y x₂ y₂,
        { exact ⟨hx, hy⟩ },
        { rw [some_add_some_of_Y_ne h₁ h₂ h₁' h₂' hx hy] at h,
          contradiction } },
      { rw [some_add_some_of_X_ne h₁ h₂ h₁' h₂' hx] at h,
        contradiction } },
    { exact λ ⟨hx, hy⟩, some_add_some_of_Y_eq h₁ h₂ h₁' h₂' hx hy } }
end

@[simp] lemma add_left_neg (P : W.point) : -P + P = 0 := by rw [add_eq_zero]

@[simp] lemma neg_add_eq_zero (P Q : W.point) : -P + Q = 0 ↔ P = Q := by rw [add_eq_zero, neg_inj]

lemma to_class_eq_zero (P : W.point) : to_class P = 0 ↔ P = 0 :=
⟨begin
  intro hP,
  rcases P with (_ | @⟨x, y, h, h'⟩),
  { refl },
  { sorry }
end, congr_arg to_class⟩

lemma to_class_injective : function.injective $ @to_class _ _ W :=
begin
  rintro (_ | ⟨h, h'⟩) _ hP,
  all_goals { rw [← neg_add_eq_zero, ← to_class_eq_zero, map_add, ← hP] },
  { exact zero_add 0 },
  { exact mk_XY_ideal'_mul_mk_XY_ideal'_of_Y_eq (equation_neg h) h (nonsingular_neg h') h' rfl rfl }
end

lemma add_comm (P Q : W.point) : P + Q = Q + P :=
to_class_injective $ by simp only [map_add, add_comm]

lemma add_assoc (P Q R : W.point) : P + Q + R = P + (Q + R) :=
to_class_injective $ by simp only [map_add, add_assoc]

noncomputable instance : add_comm_group W.point :=
{ zero         := zero,
  neg          := neg,
  add          := add,
  zero_add     := zero_add,
  add_zero     := add_zero,
  add_left_neg := add_left_neg,
  add_comm     := add_comm,
  add_assoc    := add_assoc }

end point

end addition

end weierstrass_curve
