import algebra.homology.short_complex_left_homology

noncomputable theory

open category_theory category_theory.category


open category_theory.limits
variables {C : Type*} [category C] [has_zero_morphisms C]
  (S : short_complex C)

namespace short_complex

@[nolint has_nonempty_instance]
structure right_homology_data :=
(Q H : C)
(p : S.X₂ ⟶ Q)
(ι : H ⟶ Q)
(hp₀ : S.f ≫ p = 0)
(hp : is_colimit (cokernel_cofork.of_π p hp₀))
(hι₀ : ι ≫ hp.desc (cokernel_cofork.of_π _ S.zero) = 0)
(hι : is_limit (kernel_fork.of_ι ι hι₀))

namespace right_homology_data

@[simp]
def of_coker_of_ker [has_cokernel S.f] [has_kernel (cokernel.desc S.f S.g S.zero)] :
  S.right_homology_data :=
{ Q := cokernel S.f,
  H := kernel (cokernel.desc S.f S.g S.zero),
  p := cokernel.π _,
  ι := kernel.ι _,
  hp₀ := cokernel.condition _,
  hp := cokernel_is_cokernel _,
  hι₀ := kernel.condition _,
  hι := kernel_is_kernel _, }

attribute [simp, reassoc] hp₀ hι₀
variables {S} (h : right_homology_data S) {A : C}

instance : epi h.p :=
⟨λ Y l₁ l₂, cofork.is_colimit.hom_ext h.hp⟩

instance : mono h.ι :=
⟨λ Y l₁ l₂, fork.is_limit.hom_ext h.hι⟩

def desc_Q (k : S.X₂ ⟶ A) (hk : S.f ≫ k = 0) : h.Q ⟶ A :=
h.hp.desc (cokernel_cofork.of_π k hk)

@[simp, reassoc]
lemma p_desc_Q (k : S.X₂ ⟶ A) (hk : S.f ≫ k = 0) :
  h.p ≫ h.desc_Q k hk = k :=
h.hp.fac _ walking_parallel_pair.one

@[simp]
def desc_H (k : S.X₂ ⟶ A) (hk : S.f ≫ k = 0) : h.H ⟶ A :=
  h.ι ≫ h.desc_Q k hk

/-- The morphism `h.Q ⟶ S.X₃` induced by `S.g : S.X₂ ⟶ S.X₃` and the fact that
`h.Q` is a cokernel of `S.f : S.X₁ ⟶ S.X₂`. -/
def g' : h.Q ⟶ S.X₃ := h.desc_Q S.g S.zero

@[simp, reassoc]
lemma p_g' : h.p ≫ h.g' = S.g :=
p_desc_Q _ _ _

@[simp, reassoc]
lemma ι_g' : h.ι ≫ h.g' = 0 := h.hι₀

lemma ι_desc_Q_eq_zero_of_boundary (k : S.X₂ ⟶ A) (x : S.X₃ ⟶ A) (hx : k = S.g ≫ x) :
  h.ι ≫ h.desc_Q k (by rw [hx, S.zero_assoc, zero_comp]) = 0 :=
begin
  rw [show 0 = h.ι ≫ h.g' ≫ x, by simp],
  congr' 1,
  simp only [← cancel_epi h.p, hx, p_desc_Q, p_g'_assoc],
end

/-- For `h : homology_ful_data S`, this is a restatement of `h.hι`, saying that
`ι : h.H ⟶ h.Q` is a kernel of `h.g' : h.Q ⟶ S.X₃`. -/
@[simp]
def hι' : is_limit (kernel_fork.of_ι h.ι h.ι_g') := h.hι

def lift_H (k : A ⟶ h.Q) (hk : k ≫ h.g' = 0) :
  A ⟶ h.H :=
h.hι.lift (kernel_fork.of_ι k hk)

@[simp, reassoc]
lemma lift_H_ι (k : A ⟶ h.Q) (hk : k ≫ h.g' = 0) :
  h.lift_H k hk ≫ h.ι = k :=
h.hι.fac (kernel_fork.of_ι k hk) walking_parallel_pair.zero

variable (S)

@[simp]
def of_colimit_cokernel_cofork (hg : S.g = 0) (c : cokernel_cofork S.f) (hc : is_colimit c) :
  S.right_homology_data :=
{ Q := c.X,
  H := c.X,
  p := c.π,
  ι := 𝟙 _,
  hp₀ := cokernel_cofork.condition _,
  hp := is_colimit.of_iso_colimit hc (cofork.ext (iso.refl _) (by tidy)),
  hι₀ := cofork.is_colimit.hom_ext hc begin
    dsimp,
    simp only [hg, id_comp, cofork.is_colimit.π_desc, cokernel_cofork.π_of_π, comp_zero],
  end,
  hι := kernel_zero _ begin
    apply cofork.is_colimit.hom_ext hc,
    dsimp,
    simp only [hg, id_comp, cofork.is_colimit.π_desc, cokernel_cofork.π_of_π, comp_zero],
  end }

@[simp]
def of_has_cokernel [has_cokernel S.f] (hg : S.g = 0) : S.right_homology_data :=
of_colimit_cokernel_cofork S hg _ (cokernel_is_cokernel _)

@[simp]
def of_limit_kernel_fork (hf : S.f = 0) (c : kernel_fork S.g) (hc : is_limit c) :
  S.right_homology_data :=
{ Q := S.X₂,
  H := c.X,
  p := 𝟙 _,
  ι := c.ι,
  hp₀ := by rw [comp_id, hf],
  hp := cokernel_zero _ hf,
  hι₀ := kernel_fork.condition _,
  hι := is_limit.of_iso_limit hc (fork.ext (iso.refl _) (by tidy)), }

@[simp]
def of_has_kernel [has_kernel S.g] (hf : S.f = 0) : S.right_homology_data :=
of_limit_kernel_fork S hf _ (kernel_is_kernel _)

@[simp]
def of_zeros (hf : S.f = 0) (hg : S.g = 0) :
  S.right_homology_data :=
{ Q := S.X₂,
  H := S.X₂,
  p := 𝟙 _,
  ι := 𝟙 _,
  hp₀ := by rw [comp_id, hf],
  hp := cokernel_zero _ hf,
  hι₀ := by { dsimp, rw [id_comp, hg], },
  hι := kernel_zero _ hg, }

@[simp] lemma of_zeros_p (hf : S.f = 0) (hg : S.g = 0) : (of_zeros S hf hg).p = 𝟙 _ := rfl
@[simp] lemma of_zeros_g' (hf : S.f = 0) (hg : S.g = 0) :
  (of_zeros S hf hg).g' = S.g :=
by rw [← cancel_epi (of_zeros S hf hg).p, p_g', of_zeros_p, id_comp]

end right_homology_data

class has_right_homology : Prop :=
(cond : nonempty S.right_homology_data)

def some_right_homology_data [has_right_homology S] :
  S.right_homology_data := has_right_homology.cond.some

variable {S}

lemma has_right_homology.mk' (h : S.right_homology_data) : has_right_homology S :=
⟨nonempty.intro h⟩

@[priority 100]
instance has_right_homology_of_coker_of_ker
  [has_cokernel S.f] [has_kernel (cokernel.desc S.f S.g S.zero)] :
  S.has_right_homology := has_right_homology.mk' (right_homology_data.of_coker_of_ker S)

instance has_right_homology_of_has_cokernel {X Y : C} (f : X ⟶ Y) (Z : C)
  [has_cokernel f] :
  (short_complex.mk f (0 : Y ⟶ Z) comp_zero).has_right_homology :=
has_right_homology.mk' (right_homology_data.of_has_cokernel _ rfl)

instance has_right_homology_of_has_kernel {Y Z : C} (g : Y ⟶ Z) (X : C)
  [has_kernel g] :
  (short_complex.mk (0 : X ⟶ Y) g zero_comp).has_right_homology :=
has_right_homology.mk' (right_homology_data.of_has_kernel _ rfl)

instance has_right_homology_of_zeros (X Y Z : C) :
  (short_complex.mk (0 : X ⟶ Y) (0 : Y ⟶ Z) zero_comp).has_right_homology :=
has_right_homology.mk' (right_homology_data.of_zeros _ rfl rfl)

@[simp]
def left_homology_data.op (h : left_homology_data S) :
  right_homology_data S.op :=
{ Q := opposite.op h.K,
  H := opposite.op h.H,
  p := h.i.op,
  ι := h.π.op,
  hp₀ := quiver.hom.unop_inj h.hi₀,
  hp := kernel_fork.is_limit.of_ι_op _ _ h.hi,
  hι₀ := quiver.hom.unop_inj h.hπ₀,
  hι := cokernel_cofork.is_colimit.of_π_op _ _ h.hπ, }

@[simp] lemma left_homology_data.op_p (h : left_homology_data S) : h.op.p = h.i.op := rfl
@[simp] lemma left_homology_data.op_ι (h : left_homology_data S) : h.op.ι = h.π.op := rfl
@[simp] lemma left_homology_data.op_g' (h : left_homology_data S) : h.op.g' = h.f'.op := rfl

@[simp]
def right_homology_data.op (h : right_homology_data S) :
  left_homology_data S.op :=
{ K := opposite.op h.Q,
  H := opposite.op h.H,
  i := h.p.op,
  π := h.ι.op,
  hi₀ := quiver.hom.unop_inj h.hp₀,
  hi := cokernel_cofork.is_colimit.of_π_op _ _ h.hp,
  hπ₀ := quiver.hom.unop_inj h.hι₀,
  hπ := kernel_fork.is_limit.of_ι_op _ _ h.hι, }

@[simp] lemma right_homology_data.op_i (h : right_homology_data S) : h.op.i = h.p.op := rfl
@[simp] lemma right_homology_data.op_π (h : right_homology_data S) : h.op.π = h.ι.op := rfl
@[simp] lemma right_homology_data.op_f' (h : right_homology_data S) : h.op.f' = h.g'.op := rfl

instance [has_left_homology S] : has_right_homology S.op :=
has_right_homology.mk' S.some_left_homology_data.op

instance [has_right_homology S] : has_left_homology S.op :=
has_left_homology.mk' S.some_right_homology_data.op

@[simp]
def left_homology_data.unop (h : left_homology_data S.op) :
  right_homology_data S :=
{ Q := opposite.unop h.K,
  H := opposite.unop h.H,
  p := h.i.unop,
  ι := h.π.unop,
  hp₀ := quiver.hom.op_inj h.hi₀,
  hp := kernel_fork.is_limit.of_ι_unop _ _ h.hi,
  hι₀ := quiver.hom.op_inj h.hπ₀,
  hι := cokernel_cofork.is_colimit.of_π_unop _ _ h.hπ, }

@[simp] lemma left_homology_data.unop_p (h : left_homology_data S.op) : h.unop.p = h.i.unop := rfl
@[simp] lemma left_homology_data.unop_ι (h : left_homology_data S.op) : h.unop.ι = h.π.unop := rfl
@[simp] lemma left_homology_data.unop_g' (h : left_homology_data S.op) : h.unop.g' = h.f'.unop := rfl

@[simp]
def right_homology_data.unop (h : right_homology_data S.op) :
  left_homology_data S :=
{ K := opposite.unop h.Q,
  H := opposite.unop h.H,
  i := h.p.unop,
  π := h.ι.unop,
  hi₀ := quiver.hom.op_inj h.hp₀,
  hi := cokernel_cofork.is_colimit.of_π_unop _ _ h.hp,
  hπ₀ := quiver.hom.op_inj h.hι₀,
  hπ := kernel_fork.is_limit.of_ι_unop _ _ h.hι, }

@[simp] lemma right_homology_data.unop_i (h : right_homology_data S.op) : h.unop.i = h.p.unop := rfl
@[simp] lemma right_homology_data.unop_π (h : right_homology_data S.op) : h.unop.π = h.ι.unop := rfl
@[simp] lemma right_homology_data.unop_f' (h : right_homology_data S.op) :
  h.unop.f' = h.g'.unop := rfl

section

variable {S' : short_complex Cᵒᵖ}

@[simp]
def left_homology_data.unop' (h : left_homology_data S') :
  right_homology_data S'.unop :=
{ Q := opposite.unop h.K,
  H := opposite.unop h.H,
  p := h.i.unop,
  ι := h.π.unop,
  hp₀ := quiver.hom.op_inj h.hi₀,
  hp := kernel_fork.is_limit.of_ι_unop _ _ h.hi,
  hι₀ := quiver.hom.op_inj h.hπ₀,
  hι := cokernel_cofork.is_colimit.of_π_unop _ _ h.hπ, }

@[simp] lemma left_homology_data.unop'_p (h : left_homology_data S') : h.unop'.p = h.i.unop := rfl
@[simp] lemma left_homology_data.unop'_ι (h : left_homology_data S') : h.unop'.ι = h.π.unop := rfl
@[simp] lemma left_homology_data.unop'_g' (h : left_homology_data S') : h.unop'.g' = h.f'.unop := rfl

@[simp]
def right_homology_data.unop' (h : right_homology_data S') :
  left_homology_data S'.unop :=
{ K := opposite.unop h.Q,
  H := opposite.unop h.H,
  i := h.p.unop,
  π := h.ι.unop,
  hi₀ := quiver.hom.op_inj h.hp₀,
  hi := cokernel_cofork.is_colimit.of_π_unop _ _ h.hp,
  hπ₀ := quiver.hom.op_inj h.hι₀,
  hπ := kernel_fork.is_limit.of_ι_unop _ _ h.hι, }

@[simp] lemma right_homology_data.unop'_i (h : right_homology_data S') : h.unop'.i = h.p.unop := rfl
@[simp] lemma right_homology_data.unop'_π (h : right_homology_data S') : h.unop'.π = h.ι.unop := rfl
@[simp] lemma right_homology_data.unop'_f' (h : right_homology_data S') :
  h.unop'.f' = h.g'.unop := rfl

end

variables {S₁ S₂ S₃ : short_complex C}

namespace right_homology_data

@[simp]
def of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : right_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : right_homology_data S₂ :=
begin
  haveI : epi (op_map φ).τ₁ := by { dsimp, apply_instance, },
  haveI : is_iso (op_map φ).τ₂ := by { dsimp, apply_instance, },
  haveI : mono (op_map φ).τ₃ := by { dsimp, apply_instance, },
  exact (left_homology_data.of_epi_of_is_iso_of_mono' (op_map φ) h.op).unop,
end

@[simp]
lemma of_epi_of_is_iso_of_mono_p (φ : S₁ ⟶ S₂) (h : right_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    (right_homology_data.of_epi_of_is_iso_of_mono φ h).p = inv φ.τ₂ ≫ h.p :=
begin
  change (h.p.op ≫ inv φ.τ₂.op).unop = _,
  simp only [quiver.hom.unop_op, unop_comp, unop_inv],
end

@[simp]
lemma of_epi_of_is_iso_of_mono_g' (φ : S₁ ⟶ S₂) (h : right_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    (of_epi_of_is_iso_of_mono φ h).g' = h.g' ≫ φ.τ₃ :=
begin
  rw [← cancel_epi (of_epi_of_is_iso_of_mono φ h).p, p_g'],
  simp only [of_epi_of_is_iso_of_mono_p, assoc, p_g'_assoc, is_iso.eq_inv_comp, φ.comm₂₃],
end

@[simp]
lemma of_epi_of_is_iso_of_mono_ι (φ : S₁ ⟶ S₂) (h : right_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    (of_epi_of_is_iso_of_mono φ h).ι = h.ι := rfl

@[simp]
def of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) (h : right_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : right_homology_data S₁ :=
begin
  haveI : epi (op_map φ).τ₁ := by { dsimp, apply_instance, },
  haveI : is_iso (op_map φ).τ₂ := by { dsimp, apply_instance, },
  haveI : mono (op_map φ).τ₃ := by { dsimp, apply_instance, },
  exact (left_homology_data.of_epi_of_is_iso_of_mono (op_map φ) h.op).unop,
end

@[simp]
lemma of_epi_of_is_iso_of_mono'_p (φ : S₁ ⟶ S₂) (h : right_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    (of_epi_of_is_iso_of_mono' φ h).p = φ.τ₂ ≫ h.p := rfl

@[simp]
lemma of_epi_of_is_iso_of_mono'_g'_τ₃ (φ : S₁ ⟶ S₂) (h : right_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  (of_epi_of_is_iso_of_mono' φ h).g' ≫ φ.τ₃ = h.g' :=
by rw [← cancel_epi (of_epi_of_is_iso_of_mono' φ h).p, p_g'_assoc,
    of_epi_of_is_iso_of_mono'_p, assoc, p_g', φ.comm₂₃]

@[simp]
lemma of_epi_of_is_iso_of_mono'_ι (φ : S₁ ⟶ S₂) (h : right_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    (of_epi_of_is_iso_of_mono' φ h).ι = h.ι := rfl

def of_iso (e : S₁ ≅ S₂) (h₁ : right_homology_data S₁) : right_homology_data S₂ :=
h₁.of_epi_of_is_iso_of_mono e.hom

end right_homology_data

lemma has_right_homology_of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) [has_right_homology S₁]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_right_homology S₂ :=
has_right_homology.mk' (right_homology_data.of_epi_of_is_iso_of_mono φ S₁.some_right_homology_data)

lemma has_right_homology_of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) [has_right_homology S₂]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_right_homology S₁ :=
has_right_homology.mk' (right_homology_data.of_epi_of_is_iso_of_mono' φ S₂.some_right_homology_data)

lemma has_right_homology_of_iso {S₁ S₂ : short_complex C}
  (e : S₁ ≅ S₂) [has_right_homology S₁] : has_right_homology S₂ :=
has_right_homology_of_epi_of_is_iso_of_mono e.hom

variables (φ : S₁ ⟶ S₂)
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data)

structure right_homology_map_data :=
(φQ : h₁.Q ⟶ h₂.Q)
(φH : h₁.H ⟶ h₂.H)
(commp' : h₁.p ≫ φQ = φ.τ₂ ≫ h₂.p . obviously)
(commg'' : φQ ≫ h₂.g' = h₁.g' ≫ φ.τ₃ . obviously)
(commι' : φH ≫ h₂.ι = h₁.ι ≫ φQ . obviously)

namespace right_homology_map_data

restate_axiom commp'
restate_axiom commg''
restate_axiom commι'

attribute [simp, reassoc] commp commg' commι

@[simps]
def zero (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  right_homology_map_data 0 h₁ h₂ :=
{ φQ := 0,
  φH := 0, }

@[simps]
def id (h : S.right_homology_data) : right_homology_map_data (𝟙 S) h h :=
{ φQ := 𝟙 _,
  φH := 𝟙 _, }

@[simps]
def comp {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃} {h₁ : S₁.right_homology_data}
  {h₂ : S₂.right_homology_data} {h₃ : S₃.right_homology_data}
  (ψ : right_homology_map_data φ h₁ h₂) (ψ' : right_homology_map_data φ' h₂ h₃) :
  right_homology_map_data (φ ≫ φ') h₁ h₃ :=
{ φQ := ψ.φQ ≫ ψ'.φQ,
  φH := ψ.φH ≫ ψ'.φH, }

instance : subsingleton (right_homology_map_data φ h₁ h₂) :=
⟨λ ψ₁ ψ₂, begin
  have hQ : ψ₁.φQ = ψ₂.φQ := by simp [← cancel_epi h₁.p],
  have hH : ψ₁.φH = ψ₂.φH := by simp [← cancel_mono h₂.ι, hQ],
  cases ψ₁,
  cases ψ₂,
  simp only,
  tauto,
end⟩

instance : inhabited (right_homology_map_data φ h₁ h₂) :=
⟨begin
  let φQ : h₁.Q ⟶ h₂.Q := h₁.desc_Q (φ.τ₂ ≫ h₂.p)
    (by rw [← φ.comm₁₂_assoc, h₂.hp₀, comp_zero]),
  have commg' : φQ ≫ h₂.g' = h₁.g' ≫ φ.τ₃,
  { simp only [← cancel_epi h₁.p, assoc, right_homology_data.p_desc_Q_assoc,
      right_homology_data.p_g'_assoc, right_homology_data.p_g', φ.comm₂₃], },
  let φH : h₁.H ⟶ h₂.H := h₂.lift_H (h₁.ι ≫ φQ)
    (by rw [assoc, commg', h₁.ι_g'_assoc, zero_comp]),
  exact ⟨φQ, φH, by simp, commg', by simp⟩,
end⟩

instance : unique (right_homology_map_data φ h₁ h₂) := unique.mk' _

def some : right_homology_map_data φ h₁ h₂ := default

variables {φ h₁ h₂}

lemma congr_φH {γ₁ γ₂ : right_homology_map_data φ h₁ h₂} (eq : γ₁ = γ₂) :
  γ₁.φH = γ₂.φH := by rw eq
lemma congr_φQ {γ₁ γ₂ : right_homology_map_data φ h₁ h₂} (eq : γ₁ = γ₂) :
  γ₁.φQ = γ₂.φQ := by rw eq

@[simp]
def of_zeros {φ : S₁ ⟶ S₂} (hf₁ : S₁.f = 0) (hg₁ : S₁.g = 0) (hf₂ : S₂.f = 0) (hg₂ : S₂.g = 0) :
  right_homology_map_data φ (right_homology_data.of_zeros S₁ hf₁ hg₁)
    (right_homology_data.of_zeros S₂ hf₂ hg₂) :=
{ φQ := φ.τ₂,
  φH := φ.τ₂,
  commg'' := by simp only [φ.comm₂₃, right_homology_data.of_zeros_g'], }

end right_homology_map_data

variable (S)

def right_homology [has_right_homology S] : C := S.some_right_homology_data.H
def cycles_co [has_right_homology S] : C := S.some_right_homology_data.Q
def right_homology_ι [has_right_homology S] : S.right_homology ⟶ S.cycles_co :=
  S.some_right_homology_data.ι
def p_cycles_co [has_right_homology S] : S.X₂ ⟶ S.cycles_co := S.some_right_homology_data.p
def from_cycles_co [has_right_homology S] : S.cycles_co ⟶ S.X₃ := S.some_right_homology_data.g'

@[simp] lemma f_cycles_co_p [has_right_homology S] : S.f ≫ S.p_cycles_co = 0 :=
S.some_right_homology_data.hp₀

@[simp, reassoc] lemma p_from_cycles_co [has_right_homology S] :
  S.p_cycles_co ≫ S.from_cycles_co = S.g :=
S.some_right_homology_data.p_g'

instance [has_right_homology S] : epi S.p_cycles_co :=
by { dsimp only [p_cycles_co], apply_instance, }

instance [has_right_homology S] : mono S.right_homology_ι :=
by { dsimp only [right_homology_ι], apply_instance, }

variables {S S₁ S₂ S₃}

def right_homology_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  h₁.H ⟶ h₂.H := (right_homology_map_data.some φ _ _).φH

def cycles_co_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  h₁.Q ⟶ h₂.Q := (right_homology_map_data.some φ _ _).φQ

@[simp, reassoc]
lemma p_cycles_co_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  h₁.p ≫ cycles_co_map' φ h₁ h₂ = φ.τ₂ ≫ h₂.p :=
right_homology_map_data.commp _

@[simp, reassoc]
lemma right_homology_ι_naturality' (φ : S₁ ⟶ S₂)
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  right_homology_map' φ h₁ h₂ ≫ h₂.ι = h₁.ι ≫ cycles_co_map' φ h₁ h₂ :=
right_homology_map_data.commι _

def right_homology_map [has_right_homology S₁] [has_right_homology S₂]
  (φ : S₁ ⟶ S₂) : S₁.right_homology ⟶ S₂.right_homology :=
right_homology_map' φ _ _

def cycles_co_map [has_right_homology S₁] [has_right_homology S₂]
  (φ : S₁ ⟶ S₂) : S₁.cycles_co ⟶ S₂.cycles_co :=
cycles_co_map' φ _ _

@[simp, reassoc]
lemma p_cycles_co_map (φ : S₁ ⟶ S₂) [S₁.has_right_homology] [S₂.has_right_homology] :
  S₁.p_cycles_co ≫ cycles_co_map φ = φ.τ₂ ≫ S₂.p_cycles_co :=
p_cycles_co_map' _ _ _

@[reassoc]
lemma from_cycles_co_naturality (φ : S₁ ⟶ S₂) [S₁.has_right_homology] [S₂.has_right_homology] :
  cycles_co_map φ ≫ S₂.from_cycles_co = S₁.from_cycles_co ≫ φ.τ₃ :=
by simp only [←cancel_epi S₁.p_cycles_co, φ.comm₂₃, p_cycles_co_map_assoc,
  p_from_cycles_co, p_from_cycles_co_assoc]

@[simp, reassoc]
lemma right_homology_ι_naturality [has_right_homology S₁] [has_right_homology S₂]
  (φ : S₁ ⟶ S₂) :
  right_homology_map φ ≫ S₂.right_homology_ι = S₁.right_homology_ι ≫ cycles_co_map φ :=
right_homology_ι_naturality' _ _ _

namespace right_homology_map_data

variables (γ : right_homology_map_data φ h₁ h₂) {φ h₁ h₂}

lemma right_homology_map'_eq : right_homology_map' φ h₁ h₂ = γ.φH :=
right_homology_map_data.congr_φH (subsingleton.elim _ _)

lemma cycles_co_map'_eq : cycles_co_map' φ h₁ h₂ = γ.φQ :=
right_homology_map_data.congr_φQ (subsingleton.elim _ _)

end right_homology_map_data

@[simp]
lemma right_homology_map'_id (h : S.right_homology_data) :
  right_homology_map' (𝟙 S) h h = 𝟙 _ :=
(right_homology_map_data.id h).right_homology_map'_eq

@[simp]
lemma cycles_co_map'_id (h : S.right_homology_data) :
  cycles_co_map' (𝟙 S) h h = 𝟙 _ :=
(right_homology_map_data.id h).cycles_co_map'_eq

variable (S)

@[simp]
lemma right_homology_map_id [has_right_homology S] :
  right_homology_map (𝟙 S) = 𝟙 _ :=
right_homology_map'_id _

@[simp]
lemma cycles_co_map_id [has_right_homology S] :
  cycles_co_map (𝟙 S) = 𝟙 _ :=
cycles_co_map'_id _

@[simp]
lemma right_homology_map'_zero (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data):
  right_homology_map' 0 h₁ h₂ = 0 :=
(right_homology_map_data.zero h₁ h₂).right_homology_map'_eq

@[simp]
lemma cycles_co_map'_zero (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data):
  cycles_co_map' 0 h₁ h₂ = 0 :=
(right_homology_map_data.zero h₁ h₂).cycles_co_map'_eq

variables (S₁ S₂)

@[simp]
lemma right_homology_map_zero [has_right_homology S₁] [has_right_homology S₂]:
  right_homology_map (0 : S₁ ⟶ S₂) = 0 :=
right_homology_map'_zero _ _

@[simp]
lemma cycles_co_map_zero [has_right_homology S₁] [has_right_homology S₂] :
  cycles_co_map (0 : S₁ ⟶ S₂) = 0 :=
cycles_co_map'_zero _ _

variables {S₁ S₂}

lemma right_homology_map'_comp (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃)
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) (h₃ : S₃.right_homology_data) :
  right_homology_map' (φ₁ ≫ φ₂) h₁ h₃ = right_homology_map' φ₁ h₁ h₂ ≫
    right_homology_map' φ₂ h₂ h₃ :=
begin
  let γ₁ := right_homology_map_data.some φ₁ _ _,
  let γ₂ := right_homology_map_data.some φ₂ _ _,
  rw [γ₁.right_homology_map'_eq, γ₂.right_homology_map'_eq, (γ₁.comp γ₂).right_homology_map'_eq,
    right_homology_map_data.comp_φH],
end

lemma cycles_co_map'_comp (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃)
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) (h₃ : S₃.right_homology_data) :
  cycles_co_map' (φ₁ ≫ φ₂) h₁ h₃ = cycles_co_map' φ₁ h₁ h₂ ≫
    cycles_co_map' φ₂ h₂ h₃ :=
begin
  let γ₁ := right_homology_map_data.some φ₁ _ _,
  let γ₂ := right_homology_map_data.some φ₂ _ _,
  rw [γ₁.cycles_co_map'_eq, γ₂.cycles_co_map'_eq, (γ₁.comp γ₂).cycles_co_map'_eq,
    right_homology_map_data.comp_φQ],
end

@[simp]
lemma right_homology_map_comp [has_right_homology S₁] [has_right_homology S₂]
  [has_right_homology S₃] (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃) :
  right_homology_map (φ₁ ≫ φ₂) = right_homology_map φ₁ ≫ right_homology_map φ₂ :=
right_homology_map'_comp _ _ _ _ _

@[simp]
lemma cycles_co_map_comp [has_right_homology S₁] [has_right_homology S₂]
  [has_right_homology S₃] (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃) :
  cycles_co_map (φ₁ ≫ φ₂) = cycles_co_map φ₁ ≫ cycles_co_map φ₂ :=
cycles_co_map'_comp _ _ _ _ _

@[simps]
def right_homology_map_iso' (e : S₁ ≅ S₂) (h₁ : S₁.right_homology_data)
  (h₂ : S₂.right_homology_data) : h₁.H ≅ h₂.H :=
{ hom := right_homology_map' e.hom h₁ h₂,
  inv := right_homology_map' e.inv h₂ h₁,
  hom_inv_id' := by rw [← right_homology_map'_comp, e.hom_inv_id, right_homology_map'_id],
  inv_hom_id' := by rw [← right_homology_map'_comp, e.inv_hom_id, right_homology_map'_id], }

instance is_iso_right_homology_map'_of_iso (φ : S₁ ⟶ S₂) [is_iso φ]
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  is_iso (right_homology_map' φ h₁ h₂) :=
by { change is_iso (right_homology_map_iso' (as_iso φ) h₁ h₂).hom, apply_instance, }

@[simps]
def cycles_co_map_iso' (e : S₁ ≅ S₂) (h₁ : S₁.right_homology_data)
  (h₂ : S₂.right_homology_data) : h₁.Q ≅ h₂.Q :=
{ hom := cycles_co_map' e.hom h₁ h₂,
  inv := cycles_co_map' e.inv h₂ h₁,
  hom_inv_id' := by rw [← cycles_co_map'_comp, e.hom_inv_id, cycles_co_map'_id],
  inv_hom_id' := by rw [← cycles_co_map'_comp, e.inv_hom_id, cycles_co_map'_id], }

instance is_iso_cycles_co_map'_of_iso (φ : S₁ ⟶ S₂) [is_iso φ]
  (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  is_iso (cycles_co_map' φ h₁ h₂) :=
by { change is_iso (cycles_co_map_iso' (as_iso φ) h₁ h₂).hom, apply_instance, }

@[simps]
def right_homology_map_iso (e : S₁ ≅ S₂) [S₁.has_right_homology]
  [S₂.has_right_homology] : S₁.right_homology ≅ S₂.right_homology :=
{ hom := right_homology_map e.hom,
  inv := right_homology_map e.inv,
  hom_inv_id' := by rw [← right_homology_map_comp, e.hom_inv_id, right_homology_map_id],
  inv_hom_id' := by rw [← right_homology_map_comp, e.inv_hom_id, right_homology_map_id], }

instance is_iso_right_homology_map_of_iso (φ : S₁ ⟶ S₂) [is_iso φ] [S₁.has_right_homology]
  [S₂.has_right_homology] :
  is_iso (right_homology_map φ) :=
by { change is_iso (right_homology_map_iso (as_iso φ)).hom, apply_instance, }

@[simps]
def cycles_co_map_iso (e : S₁ ≅ S₂) [S₁.has_right_homology]
  [S₂.has_right_homology] : S₁.cycles_co ≅ S₂.cycles_co :=
{ hom := cycles_co_map e.hom,
  inv := cycles_co_map e.inv,
  hom_inv_id' := by rw [← cycles_co_map_comp, e.hom_inv_id, cycles_co_map_id],
  inv_hom_id' := by rw [← cycles_co_map_comp, e.inv_hom_id, cycles_co_map_id], }

instance is_iso_cycles_co_map_of_iso (φ : S₁ ⟶ S₂) [is_iso φ] [S₁.has_right_homology]
  [S₂.has_right_homology] :
  is_iso (cycles_co_map φ) :=
by { change is_iso (cycles_co_map_iso (as_iso φ)).hom, apply_instance, }

variable {S}

def right_homology_data.right_homology_iso (h : S.right_homology_data) [S.has_right_homology] :
  S.right_homology ≅ h.H := right_homology_map_iso' (iso.refl _) _ _

def right_homology_data.cycles_co_iso (h : S.right_homology_data) [S.has_right_homology] :
  S.cycles_co ≅ h.Q := cycles_co_map_iso' (iso.refl _) _ _

@[simp, reassoc]
lemma right_homology_data.p_comp_cycles_co_iso_inv (h : S.right_homology_data)
  [S.has_right_homology] :
  h.p ≫ h.cycles_co_iso.inv = S.p_cycles_co :=
begin
  dsimp [p_cycles_co, right_homology_data.cycles_co_iso],
  simp only [p_cycles_co_map', id_τ₂, id_comp],
end

@[simp, reassoc]
lemma right_homology_data.cycles_co_iso_hom_comp_p (h : S.right_homology_data)
  [S.has_right_homology] :
  S.p_cycles_co ≫ h.cycles_co_iso.hom = h.p :=
by simp only [← h.p_comp_cycles_co_iso_inv, assoc, iso.inv_hom_id, comp_id]

@[simps]
def left_homology_map_data.op {S₁ S₂ : short_complex C} {φ : S₁ ⟶ S₂}
  {h₁ : S₁.left_homology_data} {h₂ : S₂.left_homology_data}
  (ψ : left_homology_map_data φ h₁ h₂) :
  right_homology_map_data (op_map φ) h₂.op h₁.op :=
{ φQ := ψ.φK.op,
  φH := ψ.φH.op,
  commp' := quiver.hom.unop_inj (by simp),
  commg'' := quiver.hom.unop_inj (by simp),
  commι' := quiver.hom.unop_inj (by simp), }

@[simps]
def left_homology_map_data.unop' {S₁ S₂ : short_complex Cᵒᵖ} {φ : S₁ ⟶ S₂}
  {h₁ : S₁.left_homology_data} {h₂ : S₂.left_homology_data}
  (ψ : left_homology_map_data φ h₁ h₂) :
  right_homology_map_data (unop'_map φ) h₂.unop' h₁.unop' :=
{ φQ := ψ.φK.unop,
  φH := ψ.φH.unop,
  commp' := quiver.hom.op_inj (by simp),
  commg'' := quiver.hom.op_inj (by simp),
  commι' := quiver.hom.op_inj (by simp), }

@[simps]
def left_homology_map_data.unop {S₁ S₂ : short_complex C} {φ : S₁.op ⟶ S₂.op}
  {h₁ : S₁.op.left_homology_data} {h₂ : S₂.op.left_homology_data}
  (ψ : left_homology_map_data φ h₁ h₂) :
  right_homology_map_data (unop_map φ) h₂.unop h₁.unop :=
{ φQ := ψ.φK.unop,
  φH := ψ.φH.unop,
  commp' := quiver.hom.op_inj (by simp),
  commg'' := quiver.hom.op_inj (by simp),
  commι' := quiver.hom.op_inj (by simp), }

@[simps]
def right_homology_map_data.op {S₁ S₂ : short_complex C} {φ : S₁ ⟶ S₂}
  {h₁ : S₁.right_homology_data} {h₂ : S₂.right_homology_data}
  (ψ : right_homology_map_data φ h₁ h₂) :
  left_homology_map_data (op_map φ) h₂.op h₁.op :=
{ φK := ψ.φQ.op,
  φH := ψ.φH.op,
  commi' := quiver.hom.unop_inj (by simp),
  commf'' := quiver.hom.unop_inj (by simp),
  commπ' := quiver.hom.unop_inj (by simp), }

@[simps]
def right_homology_map_data.unop' {S₁ S₂ : short_complex Cᵒᵖ} {φ : S₁ ⟶ S₂}
  {h₁ : S₁.right_homology_data} {h₂ : S₂.right_homology_data}
  (ψ : right_homology_map_data φ h₁ h₂) :
  left_homology_map_data (unop'_map φ) h₂.unop' h₁.unop' :=
{ φK := ψ.φQ.unop,
  φH := ψ.φH.unop,
  commi' := quiver.hom.op_inj (by simp),
  commf'' := quiver.hom.op_inj (by simp),
  commπ' := quiver.hom.op_inj (by simp), }

@[simps]
def right_homology_map_data.unop {S₁ S₂ : short_complex C} {φ : S₁.op ⟶ S₂.op}
  {h₁ : S₁.op.right_homology_data} {h₂ : S₂.op.right_homology_data}
  (ψ : right_homology_map_data φ h₁ h₂) :
  left_homology_map_data (unop_map φ) h₂.unop h₁.unop :=
{ φK := ψ.φQ.unop,
  φH := ψ.φH.unop,
  commi' := quiver.hom.op_inj (by simp),
  commf'' := quiver.hom.op_inj (by simp),
  commπ' := quiver.hom.op_inj (by simp), }

namespace right_homology_map_data

variables (γ : right_homology_map_data φ h₁ h₂) {φ h₁ h₂}

lemma right_homology_map_eq [S₁.has_right_homology] [S₂.has_right_homology] :
  right_homology_map φ = h₁.right_homology_iso.hom ≫ γ.φH ≫ h₂.right_homology_iso.inv :=
begin
  dsimp [right_homology_data.right_homology_iso, right_homology_map_iso'],
  rw [← γ.right_homology_map'_eq, ← right_homology_map'_comp, ← right_homology_map'_comp, id_comp, comp_id],
  refl,
end

lemma cycles_co_map_eq [S₁.has_right_homology] [S₂.has_right_homology] :
  cycles_co_map φ = h₁.cycles_co_iso.hom ≫ γ.φQ ≫ h₂.cycles_co_iso.inv :=
begin
  dsimp [right_homology_data.cycles_co_iso, cycles_co_map_iso'],
  rw [← γ.cycles_co_map'_eq, ← cycles_co_map'_comp, ← cycles_co_map'_comp, id_comp, comp_id],
  refl,
end

lemma right_homology_map_comm [S₁.has_right_homology] [S₂.has_right_homology] :
  right_homology_map φ ≫ h₂.right_homology_iso.hom = h₁.right_homology_iso.hom ≫ γ.φH :=
by simp only [γ.right_homology_map_eq, assoc, iso.inv_hom_id, comp_id]

lemma cycles_co_map_comm [S₁.has_right_homology] [S₂.has_right_homology] :
  cycles_co_map φ ≫ h₂.cycles_co_iso.hom = h₁.cycles_co_iso.hom ≫ γ.φQ :=
by simp only [γ.cycles_co_map_eq, assoc, iso.inv_hom_id, comp_id]

end right_homology_map_data

variable (C)

abbreviation _root_.category_with_right_homology := ∀ (S : short_complex C), S.has_right_homology

@[simps]
def right_homology_functor [category_with_right_homology C] :
  short_complex C ⥤ C :=
{ obj := λ S, S.right_homology,
  map := λ S₁ S₂, right_homology_map, }

@[simps]
def cycles_co_functor [category_with_right_homology C] :
  short_complex C ⥤ C :=
{ obj := λ S, S.cycles_co,
  map := λ S₁ S₂, cycles_co_map, }

@[simps]
def right_homology_ι_nat_trans [category_with_right_homology C] :
  right_homology_functor C ⟶ cycles_co_functor C :=
{ app := λ S, right_homology_ι S,
  naturality' := λ S₁ S₂, right_homology_ι_naturality, }

@[simps]
def p_cycles_co_nat_trans [category_with_right_homology C] :
  short_complex.π₂ ⟶ cycles_co_functor C :=
{ app := λ S, p_cycles_co S, }

@[simps]
def from_cycles_co_nat_trans [category_with_right_homology C] :
  cycles_co_functor C ⟶ π₃ :=
{ app := λ S, S.from_cycles_co,
  naturality' := λ S₁ S₂ φ, from_cycles_co_naturality φ, }

variables {C} (S)

def op_right_homology_iso [S.has_left_homology] :
  S.op.right_homology ≅ opposite.op S.left_homology :=
S.some_left_homology_data.op.right_homology_iso

def op_left_homology_iso [S.has_right_homology] :
  S.op.left_homology ≅ opposite.op S.right_homology :=
S.some_right_homology_data.op.left_homology_iso

def op_cycles_co_iso [S.has_left_homology] :
  S.op.cycles_co ≅ opposite.op S.cycles :=
S.some_left_homology_data.op.cycles_co_iso

def op_cycles_iso [S.has_right_homology] :
  S.op.cycles ≅ opposite.op S.cycles_co :=
S.some_right_homology_data.op.cycles_iso

variables {S}

@[simp]
lemma left_homology_map'_op
  (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  (left_homology_map' φ h₁ h₂).op = right_homology_map' (op_map φ) h₂.op h₁.op :=
begin
  let γ : left_homology_map_data φ h₁ h₂ := default,
  simp only [γ.left_homology_map'_eq, γ.op.right_homology_map'_eq,
    left_homology_map_data.op_φH],
end

@[simp]
lemma right_homology_map'_op
  (φ : S₁ ⟶ S₂) (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data) :
  (right_homology_map' φ h₁ h₂).op = left_homology_map' (op_map φ) h₂.op h₁.op :=
begin
  let γ : right_homology_map_data φ h₁ h₂ := default,
  simp only [γ.right_homology_map'_eq, γ.op.left_homology_map'_eq,
    right_homology_map_data.op_φH],
end

@[simp]
lemma left_homology_map_op (φ : S₁ ⟶ S₂) [has_left_homology S₁] [has_left_homology S₂] :
  (left_homology_map φ).op =
    S₂.op_right_homology_iso.inv ≫ right_homology_map (op_map φ) ≫ S₁.op_right_homology_iso.hom :=
begin
  dsimp only [left_homology_map, right_homology_map,
    op_right_homology_iso, right_homology_data.right_homology_iso,
    right_homology_map_iso', iso.refl],
  rw [left_homology_map'_op, ← right_homology_map'_comp, ← right_homology_map'_comp,
    comp_id, id_comp],
end

@[simp]
lemma right_homology_map_op (φ : S₁ ⟶ S₂) [has_right_homology S₁] [has_right_homology S₂] :
  (right_homology_map φ).op =
    S₂.op_left_homology_iso.inv ≫ left_homology_map (op_map φ) ≫ S₁.op_left_homology_iso.hom :=
begin
  dsimp only [right_homology_map, left_homology_map,
    op_left_homology_iso, left_homology_data.left_homology_iso,
    left_homology_map_iso', iso.refl],
  rw [right_homology_map'_op, ← left_homology_map'_comp, ← left_homology_map'_comp,
    comp_id, id_comp],
end

instance category_with_left_homology_op_of_category_with_right_homology
  [category_with_right_homology C] : category_with_left_homology Cᵒᵖ :=
λ S, has_left_homology_of_iso S.unop_op

instance category_with_right_homology_op_of_category_with_left_homology
  [category_with_left_homology C] : category_with_right_homology Cᵒᵖ :=
λ S, has_right_homology_of_iso S.unop_op

instance category_with_right_homology_of_category_with_left_homology
  [category_with_right_homology C] : category_with_left_homology Cᵒᵖ :=
λ S, has_left_homology_of_iso S.unop_op

@[simps]
def right_homology_functor_op_nat_iso [category_with_right_homology C] :
  (right_homology_functor C).op ≅ op_functor C ⋙ left_homology_functor Cᵒᵖ :=
nat_iso.of_components (λ S, (op_left_homology_iso S.unop).symm) (by simp)

@[simps]
def left_homology_functor_op_nat_iso [category_with_left_homology C] :
  (left_homology_functor C).op ≅ op_functor C ⋙ right_homology_functor Cᵒᵖ :=
nat_iso.of_components (λ S, (op_right_homology_iso S.unop).symm) (by simp)

namespace right_homology_map_data

@[simps]
def of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : right_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    right_homology_map_data φ h (right_homology_data.of_epi_of_is_iso_of_mono φ h) :=
{ φQ := 𝟙 _,
  φH := 𝟙 _,
  commp' := by simp only [comp_id, right_homology_data.of_epi_of_is_iso_of_mono_p, is_iso.hom_inv_id_assoc],
  commg'' := by simp only [right_homology_data.of_epi_of_is_iso_of_mono_g', id_comp],
  commι' := by simp only [comp_id, right_homology_data.of_epi_of_is_iso_of_mono_ι, id_comp], }

@[simps]
def of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) (h : right_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    right_homology_map_data φ (right_homology_data.of_epi_of_is_iso_of_mono' φ h) h :=
{ φQ := 𝟙 _,
  φH := 𝟙 _,
  commp' := by { dsimp, simp only [comp_id], },
  commg'' := by { simp only [right_homology_data.of_epi_of_is_iso_of_mono'_g'_τ₃, id_comp], },
  commι' := by { dsimp, simp only [comp_id, id_comp], }, }

end right_homology_map_data

instance (φ : S₁ ⟶ S₂) (h₁ : S₁.right_homology_data) (h₂ : S₂.right_homology_data)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  is_iso (right_homology_map' φ h₁ h₂) :=
begin
  let h₂' := right_homology_data.of_epi_of_is_iso_of_mono φ h₁,
  haveI : is_iso (right_homology_map' φ h₁ h₂'),
  { let γ := right_homology_map_data.of_epi_of_is_iso_of_mono φ h₁,
    rw γ.right_homology_map'_eq,
    dsimp,
    apply_instance, },
  have eq := right_homology_map'_comp φ (𝟙 S₂) h₁ h₂' h₂,
  rw comp_id at eq,
  rw eq,
  apply_instance,
end

instance (φ : S₁ ⟶ S₂) [S₁.has_right_homology] [S₂.has_right_homology]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  is_iso (right_homology_map φ) :=
by { dsimp only [right_homology_map], apply_instance, }

section

variables (S) (h : S.right_homology_data) {A : C} (k : S.X₂ ⟶ A) (hk : S.f ≫ k = 0)
  [has_right_homology S]

def desc_cycles_co : S.cycles_co ⟶ A :=
S.some_right_homology_data.desc_Q k hk

@[simp, reassoc]
lemma p_desc_cycles_co : S.p_cycles_co ≫ S.desc_cycles_co k hk = k :=
right_homology_data.p_desc_Q _ k hk

def cycles_co_is_cokernel : is_colimit (cokernel_cofork.of_π S.p_cycles_co S.f_cycles_co_p) :=
S.some_right_homology_data.hp

lemma is_iso_p_cycles_co_of (hf : S.f = 0) : is_iso (S.p_cycles_co) :=
cokernel_cofork.is_colimit.is_iso_π_of_zero _ S.cycles_co_is_cokernel hf

@[simps]
def cycles_co_iso_cokernel [has_cokernel S.f] : S.cycles_co ≅ cokernel S.f :=
{ hom := S.desc_cycles_co (cokernel.π S.f) (by simp),
  inv := cokernel.desc S.f S.p_cycles_co (by simp),
  hom_inv_id' := by simp only [← cancel_epi S.p_cycles_co, p_desc_cycles_co_assoc,
    cokernel.π_desc, comp_id],
  inv_hom_id' := by simp only [← cancel_epi (cokernel.π S.f), cokernel.π_desc_assoc,
    p_desc_cycles_co, comp_id], }

@[simp]
def desc_right_homology : S.right_homology ⟶ A :=
S.right_homology_ι ≫ S.desc_cycles_co k hk

lemma ι_desc_cycles_co_eq_zero_of_boundary (x : S.X₃ ⟶ A) (hx : k = S.g ≫ x) :
S.right_homology_ι ≫ S.desc_cycles_co k (by rw [hx, S.zero_assoc, zero_comp]) = 0 :=
right_homology_data.ι_desc_Q_eq_zero_of_boundary _ k x hx

@[simp, reassoc]
lemma right_homology_ι_comp_from_cycles_co :
  S.right_homology_ι ≫ S.from_cycles_co = 0 :=
S.ι_desc_cycles_co_eq_zero_of_boundary S.g (𝟙 _) (by rw comp_id)

def right_homology_is_kernel :
  is_limit (kernel_fork.of_ι S.right_homology_ι S.right_homology_ι_comp_from_cycles_co) :=
S.some_right_homology_data.hι

variable {S}

@[simp, reassoc]
lemma right_homology_data.right_homology_iso_inv_comp_right_homology_ι :
  h.right_homology_iso.inv ≫ S.right_homology_ι = h.ι ≫ h.cycles_co_iso.inv :=
begin
  dsimp only [right_homology_ι, right_homology_data.right_homology_iso,
    right_homology_map_iso', iso.refl, right_homology_data.cycles_co_iso, cycles_co_map_iso'],
  rw ← right_homology_ι_naturality',
end

@[simp, reassoc]
lemma right_homology_data.right_homology_ι_comp_cycles_co_iso_hom :
   S.right_homology_ι ≫ h.cycles_co_iso.hom = h.right_homology_iso.hom ≫ h.ι :=
by simp only [← cancel_mono h.cycles_co_iso.inv, ← cancel_epi h.right_homology_iso.inv,
  assoc, iso.hom_inv_id, comp_id, iso.inv_hom_id_assoc,
  h.right_homology_iso_inv_comp_right_homology_ι]

@[simp, reassoc]
lemma right_homology_data.cycles_co_iso_inv_comp_desc_cycles_co :
  h.cycles_co_iso.inv ≫ S.desc_cycles_co k hk = h.desc_Q k hk :=
by simp only [← cancel_epi h.p, h.p_comp_cycles_co_iso_inv_assoc, p_desc_cycles_co,
  h.p_desc_Q]

@[simp, reassoc]
lemma right_homology_data.cycles_co_iso_inv_comp_desc_cycles_co' :
  h.cycles_co_iso.hom ≫ h.desc_Q k hk =  S.desc_cycles_co k hk :=
by rw [← cancel_epi h.cycles_co_iso.inv, iso.inv_hom_id_assoc,
  h.cycles_co_iso_inv_comp_desc_cycles_co]

lemma right_homology_data.ext_iff' (f₁ f₂ : A ⟶ S.right_homology) :
  f₁ = f₂ ↔ f₁ ≫ h.right_homology_iso.hom ≫ h.ι = f₂ ≫ h.right_homology_iso.hom ≫ h.ι :=
by simp only [← cancel_mono h.right_homology_iso.hom, ← cancel_mono h.ι, assoc]

end

namespace has_right_homology

variable (S)

@[protected]
lemma has_cokernel [S.has_right_homology] : has_cokernel S.f :=
⟨⟨⟨_, S.some_right_homology_data.hp⟩⟩⟩

lemma has_kernel [S.has_right_homology] [has_cokernel S.f] :
  has_kernel (cokernel.desc S.f S.g S.zero) :=
begin
  let h := S.some_right_homology_data,
  haveI : has_limit (parallel_pair h.g' 0) := ⟨⟨⟨_, h.hι'⟩⟩⟩,
  let e : parallel_pair h.g' 0 ≅ parallel_pair (cokernel.desc S.f S.g S.zero) 0 :=
    parallel_pair.ext (is_colimit.cocone_point_unique_up_to_iso h.hp (cokernel_is_cokernel S.f))
      (iso.refl _) (by tidy) (by tidy),
  exact has_limit_of_iso e,
end

end has_right_homology

variable (S)

def right_homology_iso_kernel_desc [S.has_right_homology] [has_cokernel S.f]
  [has_kernel (cokernel.desc S.f S.g S.zero)] :
  S.right_homology ≅ kernel (cokernel.desc S.f S.g S.zero) :=
(right_homology_data.of_coker_of_ker S).right_homology_iso

namespace right_homology_data

variable {S}

lemma is_iso_g'_of_zero_f (h : right_homology_data S) (hf : S.f = 0) : is_iso h.p :=
⟨⟨h.desc_Q (𝟙 S.X₂) (by rw [hf, zero_comp]), p_desc_Q _ _ _,
  by simp only [←cancel_epi h.p, p_desc_Q_assoc, id_comp, comp_id]⟩⟩

end right_homology_data

end short_complex
