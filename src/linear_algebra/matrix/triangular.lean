/-
Copyright (c) 2022 Alexander Bentkamp. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Alexander Bentkamp
-/
import linear_algebra.matrix.block

/-
# Triangular Matrices

This file defines upper and lower triangular matrices. The definitions are based on
`matrix.block_triangular`. All properties should ideally be proved for `matrix.block_triangular` in
general and then specialized to (nonblock)-triangular matrices here.

-/

namespace matrix
open_locale big_operators
variables {α m n : Type*}
variables {R : Type*} [comm_ring R] {M : matrix m m R}

/-- An upper triangular matrix is a matrix whose entries are zero below the diagonal. -/
def upper_triangular [has_lt m] (M : matrix m m R) :=
  M.block_triangular id

/-- A lower triangular matrix is a matrix whose entries are zero above the diagonal. -/
def lower_triangular [has_lt m] (M : matrix m m R) :=
  M.block_triangular order_dual.to_dual

/-- The determinant of an upper triangular matrix is the product of the diagonal entries. -/
lemma det_of_upper_triangular [fintype m] [linear_order m] (h : M.upper_triangular) :
  M.det = ∏ i : m, M i i :=
begin
  haveI : decidable_eq R := classical.dec_eq _,
  simp_rw [h.det, finset.image_id, det_to_square_block_id],
end

/-- The determinant of a lower triangular matrix is the product of the diagonal entries. -/
lemma det_of_lower_triangular [fintype m] [linear_order m] (h : M.lower_triangular) :
  M.det = ∏ i : m, M i i :=
by { rw ←det_transpose, exact det_of_upper_triangular h.transpose }

/-- The inverse of an upper triangular matrix is upper triangular -/
lemma upper_triangular_inv_of_upper_triangular [fintype m] [linear_order m] [invertible M]
  (hM : upper_triangular M) : upper_triangular M⁻¹ :=
block_triangular_inv_of_block_triangular hM

/-- The inverse of a lower triangular matrix is lower triangular -/
lemma lower_triangular_inv_of_lower_triangular [fintype m] [linear_order m] [invertible M]
  (hM : lower_triangular M) : lower_triangular M⁻¹ :=
block_triangular_inv_of_block_triangular hM

end matrix
