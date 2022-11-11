import algebra.homology.short_complex_right_homology

noncomputable theory

open category_theory category_theory.limits category_theory.category

variables {C : Type*} [category C] [has_zero_morphisms C]

namespace short_complex

variables (S S₁ S₂ S₃ : short_complex C)

structure homology_data :=
(left : S.left_homology_data)
(right : S.right_homology_data)
(iso : left.H ≅ right.H)
(comm : left.π ≫ iso.hom ≫ right.ι = left.i ≫ right.p)

attribute [reassoc, simp] homology_data.comm

variables {S₁ S₂ S₃} (φ : S₁ ⟶ S₂) (h₁ : S₁.homology_data) (h₂ : S₂.homology_data)

structure homology_map_data :=
(left : left_homology_map_data φ h₁.left h₂.left)
(right : right_homology_map_data φ h₁.right h₂.right)

namespace homology_map_data

variables {φ h₁ h₂}

@[reassoc]
lemma comm (h : homology_map_data φ h₁ h₂) :
  h.left.φH ≫ h₂.iso.hom = h₁.iso.hom ≫ h.right.φH :=
by simp only [← cancel_epi h₁.left.π, ← cancel_mono h₂.right.ι, assoc,
    h.left.commπ_assoc, h.right.commι, h₂.comm, h.left.commi_assoc,
    h₁.comm_assoc, h.right.commp]

instance : subsingleton (homology_map_data φ h₁ h₂) :=
⟨begin
  rintro ⟨left₁, right₁⟩ ⟨left₂, right₂⟩,
  simp only [eq_iff_true_of_subsingleton, and_self],
end⟩

instance : inhabited (homology_map_data φ h₁ h₂) :=
⟨⟨default, default⟩⟩

instance : unique (homology_map_data φ h₁ h₂) := unique.mk' _

variables (φ h₁ h₂)

def some : homology_map_data φ h₁ h₂ := default

variables {φ h₁ h₂}

lemma congr_left_φH {γ₁ γ₂ : homology_map_data φ h₁ h₂} (eq : γ₁ = γ₂) :
  γ₁.left.φH = γ₂.left.φH := by rw eq

end homology_map_data

namespace homology_data

@[simps]
def of_colimit_cokernel_cofork (hg : S.g = 0) (c : cokernel_cofork S.f) (hc : is_colimit c) :
  S.homology_data :=
{ left := left_homology_data.of_colimit_cokernel_cofork S hg c hc,
  right := right_homology_data.of_colimit_cokernel_cofork S hg c hc,
  iso := iso.refl _,
  comm := by tidy, }

@[simps]
def of_has_cokernel [has_cokernel S.f] (hg : S.g = 0) : S.homology_data :=
{ left := left_homology_data.of_has_cokernel S hg,
  right := right_homology_data.of_has_cokernel S hg,
  iso := iso.refl _,
  comm := by tidy, }

@[simps]
def of_limit_kernel_fork (hf : S.f = 0) (c : kernel_fork S.g) (hc : is_limit c) :
  S.homology_data :=
{ left := left_homology_data.of_limit_kernel_fork S hf c hc,
  right := right_homology_data.of_limit_kernel_fork S hf c hc,
  iso := iso.refl _,
  comm := by tidy, }

@[simp]
def of_has_kernel [has_kernel S.g] (hf : S.f = 0) : S.homology_data :=
of_limit_kernel_fork S hf _ (kernel_is_kernel _)

@[simps]
def of_zeros (hf : S.f = 0) (hg : S.g = 0) : S.homology_data :=
{ left := left_homology_data.of_zeros S hf hg,
  right := right_homology_data.of_zeros S hf hg,
  iso := iso.refl _,
  comm := by tidy, }

@[simps]
def of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : homology_data S₂ :=
{ left := left_homology_data.of_epi_of_is_iso_of_mono φ h.left,
  right := right_homology_data.of_epi_of_is_iso_of_mono φ h.right,
  iso := h.iso,
  comm := by simp, }

@[simps]
def of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) (h : homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : homology_data S₁ :=
{ left := left_homology_data.of_epi_of_is_iso_of_mono' φ h.left,
  right := right_homology_data.of_epi_of_is_iso_of_mono' φ h.right,
  iso := h.iso,
  comm := by simp, }

@[simp]
def of_iso (e : S₁ ≅ S₂) (h₁ : homology_data S₁) : homology_data S₂ :=
h₁.of_epi_of_is_iso_of_mono e.hom

variable {S}

@[simps]
def op (h : S.homology_data) : S.op.homology_data :=
{ left := h.right.op,
  right := h.left.op,
  iso := h.iso.op,
  comm := quiver.hom.unop_inj (by simp), }

@[simps]
def unop' {S : short_complex Cᵒᵖ} (h : S.homology_data) : S.unop.homology_data :=
{ left := h.right.unop',
  right := h.left.unop',
  iso := h.iso.unop,
  comm := quiver.hom.op_inj (by simp), }

@[simps]
def unop {S : short_complex C} (h : S.op.homology_data) : S.homology_data :=
{ left := h.right.unop,
  right := h.left.unop,
  iso := h.iso.unop,
  comm := quiver.hom.op_inj (by simp), }

end homology_data

class has_homology : Prop :=
(cond : nonempty S.homology_data)

def some_homology_data [has_homology S] :
  S.homology_data := has_homology.cond.some

variable {S}

lemma has_homology.mk' (h : S.homology_data) : has_homology S :=
⟨nonempty.intro h⟩

instance [has_homology S] : has_homology S.op :=
has_homology.mk' S.some_homology_data.op

@[priority 100]
instance has_left_homology_of_has_homology [has_homology S] : has_left_homology S :=
has_left_homology.mk' S.some_homology_data.left

@[priority 100]
instance has_right_homology_of_has_homology [has_homology S] : has_right_homology S :=
has_right_homology.mk' S.some_homology_data.right

instance has_homology_of_has_cokernel {X Y : C} (f : X ⟶ Y) (Z : C)
  [has_cokernel f] :
  (short_complex.mk f (0 : Y ⟶ Z) comp_zero).has_homology :=
has_homology.mk' (homology_data.of_has_cokernel _ rfl)

instance has_homology_of_has_kernel {Y Z : C} (g : Y ⟶ Z) (X : C)
  [has_kernel g] :
  (short_complex.mk (0 : X ⟶ Y) g zero_comp).has_homology :=
has_homology.mk' (homology_data.of_has_kernel _ rfl)

instance has_homology_of_zeros (X Y Z : C) :
  (short_complex.mk (0 : X ⟶ Y) (0 : Y ⟶ Z) zero_comp).has_homology :=
has_homology.mk' (homology_data.of_zeros _ rfl rfl)

lemma has_homology_of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) [has_homology S₁]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_homology S₂ :=
has_homology.mk' (homology_data.of_epi_of_is_iso_of_mono φ S₁.some_homology_data)

lemma has_homology_of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) [has_homology S₂]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_homology S₁ :=
has_homology.mk' (homology_data.of_epi_of_is_iso_of_mono' φ S₂.some_homology_data)

lemma has_homology_of_iso (e : S₁ ≅ S₂) [has_homology S₁] :
  has_homology S₂ :=
has_homology.mk' (homology_data.of_iso e S₁.some_homology_data)

namespace homology_map_data

@[simps]
def id (h : S.homology_data) :
  homology_map_data (𝟙 S) h h :=
{ left := left_homology_map_data.id h.left,
  right := right_homology_map_data.id h.right, }

@[simps]
def comp {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃} {h₁ : S₁.homology_data}
  {h₂ : S₂.homology_data} {h₃ : S₃.homology_data}
  (ψ : homology_map_data φ h₁ h₂) (ψ' : homology_map_data φ' h₂ h₃) :
  homology_map_data (φ ≫ φ') h₁ h₃ :=
{ left := ψ.left.comp ψ'.left,
  right := ψ.right.comp ψ'.right, }

@[simps]
def op {φ : S₁ ⟶ S₂} {h₁ : S₁.homology_data} {h₂ : S₂.homology_data}
  (ψ : homology_map_data φ h₁ h₂) :
  homology_map_data (op_map φ) h₂.op h₁.op :=
{ left := ψ.right.op,
  right := ψ.left.op, }

@[simps]
def unop {S₁ S₂ : short_complex C} {φ : S₁.op ⟶ S₂.op}
  {h₁ : S₁.op.homology_data} {h₂ : S₂.op.homology_data}
  (ψ : homology_map_data φ h₁ h₂) :
  homology_map_data (unop_map φ) h₂.unop h₁.unop :=
{ left := ψ.right.unop,
  right := ψ.left.unop, }

@[simps]
def unop' {S₁ S₂ : short_complex Cᵒᵖ} {φ : S₁ ⟶ S₂} {h₁ : S₁.homology_data} {h₂ : S₂.homology_data}
  (ψ : homology_map_data φ h₁ h₂) :
  homology_map_data (unop'_map φ) h₂.unop' h₁.unop' :=
{ left := ψ.right.unop',
  right := ψ.left.unop', }

@[simps]
def of_zeros {S₁ S₂ : short_complex C} (φ : S₁ ⟶ S₂) (hf₁ : S₁.f = 0) (hg₁ : S₁.g = 0)
  (hf₂ : S₂.f = 0) (hg₂ : S₂.g = 0) :
  homology_map_data φ (homology_data.of_zeros S₁ hf₁ hg₁) (homology_data.of_zeros S₂ hf₂ hg₂) :=
{ left := left_homology_map_data.of_zeros _ _ _ _,
  right := right_homology_map_data.of_zeros _ _ _ _, }

end homology_map_data

variable (S)

def homology [has_homology S] : C := S.some_homology_data.left.H

def homology_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.homology_data) (h₂ : S₂.homology_data) :
  h₁.left.H ⟶ h₂.left.H := left_homology_map' φ _ _

def homology_map [has_homology S₁] [has_homology S₂]
  (φ : S₁ ⟶ S₂) : S₁.homology ⟶ S₂.homology :=
homology_map' φ _ _

variable {S}
lemma homology_map'_id (h : S.homology_data) :
  homology_map' (𝟙 S) h h = 𝟙 _ :=
homology_map_data.congr_left_φH (subsingleton.elim default (homology_map_data.id h))

variable (S)

@[simp]
lemma homology_map_id [has_homology S] :
  homology_map (𝟙 S) = 𝟙 _ :=
homology_map'_id _

variable {S}

lemma homology_map'_comp (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃)
  (h₁ : S₁.homology_data) (h₂ : S₂.homology_data) (h₃ : S₃.homology_data) :
  homology_map' (φ₁ ≫ φ₂) h₁ h₃ = homology_map' φ₁ h₁ h₂ ≫
    homology_map' φ₂ h₂ h₃ :=
homology_map_data.congr_left_φH
  (subsingleton.elim default ((homology_map_data.some φ₁ h₁ h₂).comp
    (homology_map_data.some φ₂ h₂ h₃)))

@[simp]
lemma homology_map_comp [has_homology S₁] [has_homology S₂] [has_homology S₃]
  (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃) :
  homology_map (φ₁ ≫ φ₂) = homology_map φ₁ ≫ homology_map φ₂ :=
homology_map'_comp _ _ _ _ _

@[simps]
def homology_map_iso' (e : S₁ ≅ S₂) (h₁ : S₁.homology_data)
  (h₂ : S₂.homology_data) : h₁.left.H ≅ h₂.left.H :=
{ hom := homology_map' e.hom h₁ h₂,
  inv := homology_map' e.inv h₂ h₁,
  hom_inv_id' := by rw [← homology_map'_comp, e.hom_inv_id, homology_map'_id],
  inv_hom_id' := by rw [← homology_map'_comp, e.inv_hom_id, homology_map'_id], }

instance is_iso_homology_map'_of_iso (φ : S₁ ⟶ S₂) [is_iso φ]
  (h₁ : S₁.homology_data) (h₂ : S₂.homology_data) :
  is_iso (homology_map' φ h₁ h₂) :=
by { change is_iso (homology_map_iso' (as_iso φ) h₁ h₂).hom, apply_instance, }

@[simps]
def homology_map_iso (e : S₁ ≅ S₂) [S₁.has_homology]
  [S₂.has_homology] : S₁.homology ≅ S₂.homology :=
{ hom := homology_map e.hom,
  inv := homology_map e.inv,
  hom_inv_id' := by rw [← homology_map_comp, e.hom_inv_id, homology_map_id],
  inv_hom_id' := by rw [← homology_map_comp, e.inv_hom_id, homology_map_id], }

instance is_iso_homology_map_of_iso (φ : S₁ ⟶ S₂) [is_iso φ] [S₁.has_homology] [S₂.has_homology] :
  is_iso (homology_map φ) :=
by { change is_iso (homology_map_iso (as_iso φ)).hom, apply_instance, }

def homology_data.homology_iso (h₁ : S.homology_data) [S.has_homology] :
  S.homology ≅ h₁.left.H := homology_map_iso' (iso.refl _) _ _

namespace homology_map_data

variables {φ h₁ h₂} (γ : homology_map_data φ h₁ h₂)

lemma homology_map'_eq : homology_map' φ h₁ h₂ = γ.left.φH := γ.left.left_homology_map'_eq

lemma homology_map_eq [S₁.has_homology] [S₂.has_homology] :
  homology_map φ = h₁.homology_iso.hom ≫ γ.left.φH ≫ h₂.homology_iso.inv :=
begin
  dsimp [homology_data.homology_iso, homology_map_iso'],
  rw [← γ.homology_map'_eq, ← homology_map'_comp, ← homology_map'_comp, comp_id, id_comp],
  refl,
end

lemma map_comm [S₁.has_homology] [S₂.has_homology] :
  homology_map φ ≫ h₂.homology_iso.hom = h₁.homology_iso.hom ≫ γ.left.φH :=
by simp only [γ.homology_map_eq, assoc, iso.inv_hom_id, comp_id]

end homology_map_data

namespace left_homology_data

def homology_iso (h : S.left_homology_data) [S.has_homology] :
  S.homology ≅ h.H :=
left_homology_map_iso' (iso.refl S) _ _

lemma ext_iff {A : C} (h : S.left_homology_data) [S.has_homology] (f₁ f₂ : S.homology ⟶ A) :
  f₁ = f₂ ↔ h.π ≫ h.homology_iso.inv ≫ f₁ = h.π ≫ h.homology_iso.inv ≫ f₂ :=
by rw [← cancel_epi h.homology_iso.inv, cancel_epi h.π]

end left_homology_data

variables {C}

def left_right_homology_comparison' (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
  h₁.H ⟶ h₂.H :=
h₂.lift_H (h₁.desc_H (h₁.i ≫ h₂.p) (by simp)) (by simp [← cancel_epi h₁.π])

lemma left_right_homology_comparison'_eq₁ (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
left_right_homology_comparison' h₁ h₂ =
  h₂.lift_H (h₁.desc_H (h₁.i ≫ h₂.p) (by simp)) (by simp [← cancel_epi h₁.π]) := rfl

@[simp, reassoc]
lemma comp_left_right_homology_comparison'_comp (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
  h₁.π ≫ left_right_homology_comparison' h₁ h₂ ≫ h₂.ι = h₁.i ≫ h₂.p :=
by simp [left_right_homology_comparison'_eq₁]

lemma left_right_homology_comparison'_eq₂ (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
left_right_homology_comparison' h₁ h₂ =
  h₁.desc_H (h₂.lift_H (h₁.i ≫ h₂.p) (by simp)) (by simp [← cancel_mono h₂.ι]) :=
by simp [← cancel_mono h₂.ι, ← cancel_epi h₁.π]

variable (S)

def left_right_homology_comparison [S.has_left_homology] [S.has_right_homology] :
  S.left_homology ⟶ S.right_homology :=
left_right_homology_comparison' _ _

@[simp, reassoc]
lemma comp_left_right_homology_comparison_comp [S.has_left_homology] [S.has_right_homology] :
  S.left_homology_π ≫ S.left_right_homology_comparison ≫ S.right_homology_ι =
    S.cycles_i ≫ S.p_cycles_co :=
by apply comp_left_right_homology_comparison'_comp

@[reassoc]
lemma left_right_homology_comparison'_naturality (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data)
  (h₂ : S₁.right_homology_data) (h₁' : S₂.left_homology_data) (h₂' : S₂.right_homology_data) :
  left_homology_map' φ h₁ h₁' ≫ left_right_homology_comparison' h₁' h₂' =
    left_right_homology_comparison' h₁ h₂ ≫ right_homology_map' φ h₂ h₂' :=
by simp only [← cancel_epi h₁.π, ← cancel_mono h₂'.ι, assoc,
    left_homology_π_naturality'_assoc, right_homology_ι_naturality',
    comp_left_right_homology_comparison'_comp,
    comp_left_right_homology_comparison'_comp_assoc,
    cycles_map'_i_assoc, p_cycles_co_map']

variable {S}

lemma left_right_homology_comparison'_compatibility (h₁ h₁' : S.left_homology_data) (h₂ h₂' : S.right_homology_data) :
  left_right_homology_comparison' h₁ h₂ = left_homology_map' (𝟙 S) h₁ h₁' ≫
    left_right_homology_comparison' h₁' h₂' ≫ right_homology_map' (𝟙 S) _ _ :=
by rw [left_right_homology_comparison'_naturality_assoc (𝟙 S) h₁ h₂ h₁' h₂',
    ← right_homology_map'_comp, comp_id, right_homology_map'_id, comp_id]

lemma left_right_homology_comparison_eq [S.has_left_homology] [S.has_right_homology]
  (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
  S.left_right_homology_comparison = h₁.left_homology_iso.hom ≫ left_right_homology_comparison' h₁ h₂ ≫
    h₂.right_homology_iso.inv :=
left_right_homology_comparison'_compatibility _ _ _ _

@[simp]
lemma left_right_homology_comparison'_eq_iso_hom (h : homology_data S) :
  left_right_homology_comparison' h.left h.right = h.iso.hom :=
by simp only [←cancel_epi h.left.π, ←cancel_mono h.right.ι,
    comp_left_right_homology_comparison'_comp, homology_data.comm]

instance is_iso_left_right_homology_comparison'_of_homology_data (h : homology_data S) :
  is_iso (left_right_homology_comparison' h.left h.right) :=
by { rw left_right_homology_comparison'_eq_iso_hom, apply_instance, }

instance is_iso_left_right_homology_comparison' [S.has_homology]
  (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
  is_iso (left_right_homology_comparison' h₁ h₂) :=
begin
  rw left_right_homology_comparison'_compatibility h₁ S.some_homology_data.left h₂
    S.some_homology_data.right,
  apply_instance,
end

instance is_iso_left_right_homology_comparison [S.has_homology] :
  is_iso S.left_right_homology_comparison :=
by { change is_iso (left_right_homology_comparison' _ _), apply_instance, }

namespace right_homology_data

def homology_iso (h : S.right_homology_data) [S.has_homology] :
  S.homology ≅ h.H :=
as_iso (left_right_homology_comparison' S.some_homology_data.left h)

lemma ext_iff {A : C} (h : S.right_homology_data) [S.has_homology] (f₁ f₂ : A ⟶ S.homology) :
  f₁ = f₂ ↔ f₁ ≫ h.homology_iso.hom ≫ h.ι = f₂ ≫ h.homology_iso.hom ≫ h.ι :=
by simp only [← cancel_mono h.homology_iso.hom, ← cancel_mono h.ι, assoc]

end right_homology_data

namespace homology_data

@[simps]
def of_is_iso_left_right_homology_comparison'
  (h₁ : S.left_homology_data) (h₂ : S.right_homology_data)
  [is_iso (left_right_homology_comparison' h₁ h₂)] :
  S.homology_data :=
{ left := h₁,
  right := h₂,
  iso := as_iso (left_right_homology_comparison' h₁ h₂),
  comm := by simp only [as_iso_hom, comp_left_right_homology_comparison'_comp], }

lemma has_homology_of_is_iso_left_right_homology_comparison'
  (h₁ : S.left_homology_data) (h₂ : S.right_homology_data)
  [is_iso (left_right_homology_comparison' h₁ h₂)] :
  S.has_homology :=
has_homology.mk' (of_is_iso_left_right_homology_comparison' h₁ h₂)

lemma has_homology_of_is_iso_left_right_homology_comparison [S.has_left_homology]
  [S.has_right_homology] [h : is_iso S.left_right_homology_comparison] :
  S.has_homology :=
begin
  haveI : is_iso (left_right_homology_comparison' S.some_left_homology_data
    S.some_right_homology_data) := h,
  exact has_homology_of_is_iso_left_right_homology_comparison' S.some_left_homology_data
    S.some_right_homology_data,
end

end homology_data

@[simps]
def homology_map_data.of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    homology_map_data φ h (homology_data.of_epi_of_is_iso_of_mono φ h) :=
{ left := left_homology_map_data.of_epi_of_is_iso_of_mono φ h.left,
  right := right_homology_map_data.of_epi_of_is_iso_of_mono φ h.right, }

@[simps]
def homology_map_data.of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) (h : homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    homology_map_data φ (homology_data.of_epi_of_is_iso_of_mono' φ h) h :=
{ left := left_homology_map_data.of_epi_of_is_iso_of_mono' φ h.left,
  right := right_homology_map_data.of_epi_of_is_iso_of_mono' φ h.right, }

variable (S)

def left_homology_iso_homology [S.has_homology] :
  S.left_homology ≅ S.homology :=
S.some_left_homology_data.homology_iso.symm

@[reassoc]
lemma left_homology_iso_homology_hom_naturality [S₁.has_homology] [S₂.has_homology]
  (φ : S₁ ⟶ S₂) :
  S₁.left_homology_iso_homology.hom ≫ homology_map φ =
    left_homology_map φ ≫ S₂.left_homology_iso_homology.hom :=
begin
  dsimp only [left_homology_iso_homology, left_homology_data.homology_iso,
    homology_map, homology_map', left_homology_map_iso', iso.symm, iso.refl,
    left_homology_map],
  rw [← left_homology_map'_comp, ← left_homology_map'_comp, id_comp, comp_id],
end

def homology_iso_right_homology [S.has_homology] :
  S.homology ≅ S.right_homology :=
S.some_right_homology_data.homology_iso

variable {S}

lemma left_homology_map'_comp_iso_hom_comp_right_homology_map'
  (h : S.homology_data) (h₁ : S.left_homology_data) (h₂ : S.right_homology_data) :
  left_homology_map' (𝟙 S) h₁ h.left ≫ h.iso.hom ≫ right_homology_map' (𝟙 S) h.right h₂ =
    left_right_homology_comparison' h₁ h₂ :=
by simpa using (left_right_homology_comparison'_compatibility h₁ h.left h₂ h.right).symm

variable (S)

@[reassoc]
lemma left_right_homology_comparison_fac [S.has_homology] :
  S.left_right_homology_comparison =
    S.left_homology_iso_homology.hom ≫ S.homology_iso_right_homology.hom :=
begin
  have eq : S.some_homology_data.iso.hom ≫ right_homology_map' (𝟙 S) _ _ =
    S.homology_iso_right_homology.hom := by simpa only [left_homology_map'_id, id_comp]
    using left_homology_map'_comp_iso_hom_comp_right_homology_map' S.some_homology_data
      S.some_homology_data.left S.some_right_homology_data,
  simpa only [eq.symm] using (left_homology_map'_comp_iso_hom_comp_right_homology_map' _ _ _).symm,
end

variable (C)
/-- We shall say that a category with homology is a category for which
all short complexes have homology. -/
abbreviation _root_.category_with_homology := ∀ (S : short_complex C), S.has_homology

/-- Assuming that all short complexes have homology, this is the homology functor. -/
@[simps]
def homology_functor [category_with_homology C] :
  short_complex C ⥤ C :=
{ obj := λ S, S.homology,
  map := λ S₁ S₂, homology_map, }

instance (φ : S₁ ⟶ S₂) [S₁.has_homology] [S₂.has_homology]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  is_iso (homology_map φ) :=
by { dsimp only [homology_map, homology_map'], apply_instance, }

section

variables [has_homology S] {A : C} {C}

def homology_π : S.cycles ⟶ S.homology :=
S.left_homology_π ≫ S.left_homology_iso_homology.hom

@[simp, reassoc]
lemma homology_π_comp_left_homology_iso_homology_inv :
  S.homology_π ≫ S.left_homology_iso_homology.inv = S.left_homology_π :=
begin
  dsimp only [homology_π],
  simp only [assoc, iso.hom_inv_id, comp_id],
end

@[simp, reassoc]
lemma to_cycles_comp_homology_π :
  S.to_cycles ≫ S.homology_π = 0 :=
begin
  dsimp only [homology_π],
  simp only [to_cycles_comp_left_homology_π_assoc, zero_comp],
end

def homology_is_cokernel :
  is_colimit (cokernel_cofork.of_π S.homology_π S.to_cycles_comp_homology_π) :=
is_colimit.of_iso_colimit S.left_homology_is_cokernel
  (cofork.ext S.left_homology_iso_homology rfl)

def homology_desc (k : S.cycles ⟶ A) (hk : S.to_cycles ≫ k = 0) :
  S.homology ⟶ A :=
S.homology_is_cokernel.desc (cokernel_cofork.of_π k hk)

@[simp, reassoc]
lemma homology_π_desc (k : S.cycles ⟶ A) (hk : S.to_cycles ≫ k = 0) :
  S.homology_π ≫ S.homology_desc k hk = k :=
cokernel_cofork.is_colimit.π_desc S.homology_is_cokernel (cokernel_cofork.of_π k hk)

/- dualise the above -/

def homology_ι : S.homology ⟶ S.cycles_co :=
S.homology_iso_right_homology.hom ≫ S.right_homology_ι

@[simp, reassoc]
lemma right_homology_iso_homology_inv_comp_homology_ι :
  S.homology_iso_right_homology.inv ≫ S.homology_ι = S.right_homology_ι :=
begin
  dsimp only [homology_ι],
  simp only [iso.inv_hom_id_assoc],
end

@[simp, reassoc]
lemma homology_ι_comp_from_cycles_co :
  S.homology_ι ≫ S.from_cycles_co = 0 :=
begin
  dsimp only [homology_ι],
  simp only [assoc, right_homology_ι_comp_from_cycles_co, comp_zero],
end

def homology_is_kernel :
  is_limit (kernel_fork.of_ι S.homology_ι S.homology_ι_comp_from_cycles_co) :=
is_limit.of_iso_limit S.right_homology_is_kernel
(fork.ext S.homology_iso_right_homology.symm (by simp))

def homology_lift (k : A ⟶ S.cycles_co) (hk : k ≫ S.from_cycles_co = 0) :
  A ⟶ S.homology :=
S.homology_is_kernel.lift (kernel_fork.of_ι k hk)

@[simp, reassoc]
lemma homology_lift_ι (k : A ⟶ S.cycles_co) (hk : k ≫ S.from_cycles_co = 0) :
  S.homology_lift k hk ≫ S.homology_ι = k :=
kernel_fork.is_limit.lift_ι S.homology_is_kernel _

@[simp, reassoc]
lemma homology_π_ι :
  S.homology_π ≫ S.homology_ι = S.cycles_i ≫ S.p_cycles_co :=
begin
  dsimp [homology_π, homology_ι],
  rw assoc,
  nth_rewrite 1 ← assoc,
  simpa only [S.left_right_homology_comparison_fac]
    using S.comp_left_right_homology_comparison_comp,
end

lemma is_iso_homology_map'_of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] (h₁ : S₁.homology_data) (h₂ : S₂.homology_data) :
  is_iso (homology_map' φ h₁ h₂) :=
begin
  have eq := homology_map'_comp φ (𝟙 S₂) h₁ (homology_data.of_epi_of_is_iso_of_mono φ h₁) h₂,
  simp only [comp_id, (homology_map_data.of_epi_of_is_iso_of_mono φ h₁).homology_map'_eq,
    homology_map_data.of_epi_of_is_iso_of_mono_left,
    left_homology_map_data.of_epi_of_is_iso_of_mono_φH, id_comp] at eq,
  rw eq,
  apply_instance,
end

end

variable {C}

def homology_iso_kernel_desc [S.has_homology] [has_cokernel S.f]
  [has_kernel (cokernel.desc S.f S.g S.zero)] :
  S.homology ≅ kernel (cokernel.desc S.f S.g S.zero) :=
(right_homology_data.of_coker_of_ker S).homology_iso

def homology_iso_cokernel_lift [S.has_homology] [has_kernel S.g]
  [has_cokernel (kernel.lift S.g S.f S.zero)] :
  S.homology ≅ cokernel (kernel.lift S.g S.f S.zero) :=
(left_homology_data.of_ker_of_coker S).homology_iso

variable {S}

@[simp, reassoc]
lemma left_homology_data.homology_π_comp_homology_iso_hom
  (h : S.left_homology_data) [S.has_homology] :
  S.homology_π ≫ h.homology_iso.hom = h.cycles_iso.hom ≫ h.π :=
begin
  rw [← h.left_homology_π_comp_left_homology_iso_hom,
    ← S.homology_π_comp_left_homology_iso_homology_inv],
  dsimp [left_homology_iso_homology, left_homology_data.homology_iso,
    left_homology_data.left_homology_iso],
  rw [assoc, ← left_homology_map'_comp, id_comp],
end

@[simp, reassoc]
lemma right_homology_data.homology_iso_hom_comp_right_homology_iso_inv
  (h : S.right_homology_data) [S.has_homology] :
  h.homology_iso.hom ≫ h.right_homology_iso.inv = S.homology_iso_right_homology.hom :=
begin
  dsimp [right_homology_data.homology_iso, homology_iso_right_homology,
    right_homology_data.right_homology_iso],
  rw [← left_homology_map'_comp_iso_hom_comp_right_homology_map'
    S.some_homology_data S.some_homology_data.left h, left_homology_map'_id, id_comp,
    ← left_homology_map'_comp_iso_hom_comp_right_homology_map' S.some_homology_data
    S.some_homology_data.left S.some_right_homology_data, assoc,
    left_homology_map'_id, id_comp, ← right_homology_map'_comp, id_comp],
end

@[simp, reassoc]
lemma right_homology_data.homology_iso_inv_comp_homology_π
  (h : S.right_homology_data) [S.has_homology] :
  h.homology_iso.inv ≫ S.homology_ι = h.ι ≫ h.cycles_co_iso.inv :=
begin
  simp only [← right_homology_data.right_homology_iso_inv_comp_right_homology_ι,
    ← S.right_homology_iso_homology_inv_comp_homology_ι,
    ← cancel_epi h.homology_iso.hom, iso.hom_inv_id_assoc,
    h.homology_iso_hom_comp_right_homology_iso_inv_assoc],
end

@[reassoc]
lemma left_homology_data.π_comp_homology_iso_inv (h : S.left_homology_data) [S.has_homology] :
  h.π ≫ h.homology_iso.inv = h.cycles_iso.inv ≫ S.homology_π :=
by simp only [← cancel_epi h.cycles_iso.hom, ← cancel_mono h.homology_iso.hom, assoc,
  iso.inv_hom_id, comp_id, iso.hom_inv_id_assoc, h.homology_π_comp_homology_iso_hom]

@[reassoc]
lemma right_homology_data.π_comp_homology_iso_inv (h : S.right_homology_data) [S.has_homology] :
  h.homology_iso.hom ≫ h.ι = S.homology_ι ≫ h.cycles_co_iso.hom :=
by simp only [← cancel_mono h.cycles_co_iso.inv, ← cancel_epi h.homology_iso.inv, assoc,
  iso.inv_hom_id_assoc, iso.hom_inv_id, comp_id,
  right_homology_data.homology_iso_inv_comp_homology_π]

@[simp, reassoc]
lemma comp_homology_map_comp [S₁.has_homology] [S₂.has_homology] (φ : S₁ ⟶ S₂)
  (h₁ : S₁.left_homology_data) (h₂ : S₂.right_homology_data) :
  h₁.π ≫ h₁.homology_iso.inv ≫ homology_map φ ≫ h₂.homology_iso.hom ≫ h₂.ι =
    h₁.i ≫ φ.τ₂ ≫ h₂.p :=
begin
  simp only [← cancel_epi h₁.cycles_iso.hom, ← cancel_mono h₂.cycles_co_iso.inv,
    assoc, left_homology_data.cycles_iso_hom_comp_i_assoc,
    right_homology_data.p_comp_cycles_co_iso_inv,
    left_homology_data.π_comp_homology_iso_inv_assoc, iso.hom_inv_id, comp_id,
    right_homology_data.π_comp_homology_iso_inv_assoc, iso.hom_inv_id_assoc],
  dsimp only [homology_π, homology_ι],
  simp only [assoc, left_homology_iso_homology_hom_naturality_assoc φ,
    left_homology_π_naturality_assoc, ← S₂.left_right_homology_comparison_fac_assoc,
    comp_left_right_homology_comparison_comp, cycles_map_i_assoc],
end

lemma π_comp_homology_map_comp_ι [S₁.has_homology] [S₂.has_homology] (φ : S₁ ⟶ S₂) :
  S₁.homology_π ≫ homology_map φ ≫ S₂.homology_ι =
    S₁.cycles_i ≫ φ.τ₂ ≫ S₂.p_cycles_co :=
begin
  dsimp [homology_π, homology_ι],
  simpa only [assoc] using comp_homology_map_comp φ
    S₁.some_left_homology_data S₂.some_right_homology_data,
end

section quasi_iso

variables [has_homology S₁] [has_homology S₂] [has_homology S₃]

@[protected]
def quasi_iso (φ : S₁ ⟶ S₂) := is_iso (homology_map φ)

lemma quasi_iso_of_iso (φ : S₁ ⟶ S₂) [is_iso φ] : quasi_iso φ :=
is_iso.of_iso (homology_map_iso (as_iso φ))

lemma quasi_iso_comp {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃} (h : quasi_iso φ) (h' : quasi_iso φ') :
  quasi_iso (φ ≫ φ') :=
begin
  unfreezingI { dsimp [quasi_iso] at ⊢ h h', },
  rw homology_map_comp,
  apply_instance,
end

lemma quasi_iso_of_comp_left {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃}
  (h : quasi_iso φ) (h' : quasi_iso (φ ≫ φ')) :
  quasi_iso φ' :=
begin
  unfreezingI { dsimp [quasi_iso] at ⊢ h h', },
  rw homology_map_comp at h',
  haveI := h,
  exact is_iso.of_is_iso_comp_left (homology_map φ) (homology_map φ'),
end

lemma quasi_iso_of_comp_right {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃}
  (h : quasi_iso φ') (h' : quasi_iso (φ ≫ φ')) :
  quasi_iso φ :=
begin
  unfreezingI { dsimp [quasi_iso] at ⊢ h h', },
  rw homology_map_comp at h',
  haveI := h',
  exact is_iso.of_is_iso_comp_right (homology_map φ) (homology_map φ'),
end

end quasi_iso

lemma left_homology_map_data.quasi_iso_iff' {φ : S₁ ⟶ S₂} {h₁ h₁' : left_homology_data S₁}
  {h₂ h₂' : left_homology_data S₂} (ψ : left_homology_map_data φ h₁ h₂) (ψ' : left_homology_map_data φ h₁' h₂')
  [S₁.has_homology] [S₂.has_homology] :
  is_iso ψ.φH ↔ is_iso ψ'.φH :=
begin
  let e := left_homology_map_iso' (iso.refl S₁) h₁ h₁',
  let e' := left_homology_map_iso' (iso.refl S₂) h₂ h₂',
  have fac₁ : ψ'.φH = e.inv ≫ ψ.φH ≫ e'.hom,
  { dsimp [e, e'],
    rw [← ψ.left_homology_map'_eq, ← ψ'.left_homology_map'_eq, ← left_homology_map'_comp,
      ← left_homology_map'_comp, id_comp, comp_id], },
  have fac₂ : ψ.φH = e.hom ≫ ψ'.φH ≫ e'.inv,
  { simp only [fac₁, assoc, e.hom_inv_id_assoc, e'.hom_inv_id, comp_id], },
  split,
  { introI,
    rw fac₁,
    apply_instance, },
  { introI,
    rw fac₂,
    apply_instance, },
end

lemma left_homology_map_data.quasi_iso_iff {φ : S₁ ⟶ S₂} {h₁ : left_homology_data S₁}
  {h₂ : left_homology_data S₂} (ψ : left_homology_map_data φ h₁ h₂)
  [S₁.has_homology] [S₂.has_homology] :
  quasi_iso φ ↔ is_iso ψ.φH :=
left_homology_map_data.quasi_iso_iff' _ _

lemma homology_map_data.quasi_iso_iff' {φ : S₁ ⟶ S₂} {h : homology_data S}
  {h : homology_data S₂} (ψ : homology_map_data φ h₁ h₂)
  [S₁.has_homology] [S₂.has_homology] :
  is_iso ψ.left.φH ↔ is_iso ψ.right.φH :=
begin
  have fac₁ : ψ.right.φH = h₁.iso.inv ≫ ψ.left.φH ≫ h₂.iso.hom,
  { simp only [ψ.comm, iso.inv_hom_id_assoc], },
  have fac₂ : ψ.left.φH = h₁.iso.hom ≫ ψ.right.φH ≫ h₂.iso.inv,
  { simp only [← reassoc_of ψ.comm, iso.hom_inv_id, comp_id], },
  split,
  { introI,
    rw fac₁,
    apply_instance, },
  { introI,
    rw fac₂,
    apply_instance, },
end

lemma right_homology_map_data.quasi_iso_iff {φ : S₁ ⟶ S₂} {h₁ : right_homology_data S₁}
  {h₂ : right_homology_data S₂} (ψ : right_homology_map_data φ h₁ h₂)
  [S₁.has_homology] [S₂.has_homology] :
  quasi_iso φ ↔ is_iso ψ.φH :=
begin
  let h₁' := S₁.some_homology_data,
  let h₂' := S₂.some_homology_data,
  let ψ' : left_homology_map_data φ h₁'.left h₂'.left := default,
  let h₁'' := homology_data.of_is_iso_left_right_homology_comparison' h₁'.left h₁,
  let h₂'' := homology_data.of_is_iso_left_right_homology_comparison' h₂'.left h₂,
  let Φ : homology_map_data φ h₁'' h₂'' := ⟨ψ', ψ⟩,
  change is_iso (Φ.left.φH) ↔ is_iso (Φ.right.φH),
  have fac₁ : Φ.right.φH = h₁''.iso.inv ≫ Φ.left.φH ≫ h₂''.iso.hom,
  { rw [Φ.comm, iso.inv_hom_id_assoc], },
  have fac₂ : Φ.left.φH = h₁''.iso.hom ≫ Φ.right.φH ≫ h₂''.iso.inv,
  { rw [← Φ.comm_assoc, iso.hom_inv_id, comp_id], },
  split,
  { introI,
    rw fac₁,
    apply_instance, },
  { introI,
    rw fac₂,
    apply_instance, },
end

end short_complex
