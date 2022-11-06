import category_theory.limits.preserves.shapes.zero
import category_theory.limits.preserves.finite
import category_theory.limits.shapes.finite_limits
import category_theory.limits.shapes.kernels
import tactic.equiv_rw

noncomputable theory

open category_theory category_theory.category category_theory.limits
open_locale zero_object

namespace category_theory.limits

variables {C : Type*} [category C] [has_zero_morphisms C]
/-- change kernel.lift to get better definitional properties -/
abbreviation kernel.lift₀
  {W X Y : C} (f : X ⟶ Y) [has_kernel f] (k : W ⟶ X) (h : k ≫ f = 0) : W ⟶ kernel f :=
(kernel_is_kernel f).lift (kernel_fork.of_ι k h)

@[simp, reassoc]
lemma kernel.lift₀_ι
  {W X Y : C} (f : X ⟶ Y) [has_kernel f] (k : W ⟶ X) (h : k ≫ f = 0) :
  kernel.lift₀ f k h ≫ kernel.ι f = k :=
(kernel_is_kernel f).fac (kernel_fork.of_ι k h) walking_parallel_pair.zero

/-- change cokernel.desc to get better definitional properties -/
abbreviation cokernel.desc₀
  {W X Y : C} (f : X ⟶ Y) [has_cokernel f] (k : Y ⟶ W) (h : f ≫ k = 0) : cokernel f ⟶ W :=
(cokernel_is_cokernel f).desc (cokernel_cofork.of_π k h)

@[simp, reassoc]
lemma cokernel.π_desc₀
  {W X Y : C} (f : X ⟶ Y) [has_cokernel f] (k : Y ⟶ W) (h : f ≫ k = 0) :
  cokernel.π f ≫ cokernel.desc₀ f k h = k :=
(cokernel_is_cokernel f).fac (cokernel_cofork.of_π k h) walking_parallel_pair.one

@[simps]
def kernel_zero {X Y : C} (f : X ⟶ Y) (hf : f = 0) :
  is_limit (kernel_fork.of_ι (𝟙 X) (show 𝟙 X ≫ f = 0, by rw [hf, comp_zero])) :=
kernel_fork.is_limit.of_ι _ _ (λ A x hx, x) (λ A x hx, comp_id _)
  (λ A x hx b hb, by rw [← hb, comp_id])

/-- to be moved -/
@[simps]
def cokernel_zero {X Y : C} (f : X ⟶ Y) (hf : f = 0) :
  is_colimit (cokernel_cofork.of_π (𝟙 Y) (show f ≫ 𝟙 Y = 0, by rw [hf, zero_comp])) :=
cokernel_cofork.is_colimit.of_π _ _ (λ A x hx, x) (λ A x hx, id_comp _)
  (λ A x hx b hb, by rw [← hb, id_comp])

end category_theory.limits

open category_theory.limits

variables (C D : Type*) [category C] [category D]

/-- A short complex in a category `C` with zero composition is the datum
of two composable morphisms `f : X₁ ⟶ X₂` and `g : X₂ ⟶ X₃` such that
`f ≫ g = 0`. -/
structure short_complex [has_zero_morphisms C] :=
{X₁ X₂ X₃ : C}
(f : X₁ ⟶ X₂)
(g : X₂ ⟶ X₃)
(zero : f ≫ g = 0)

variables {C} [has_zero_morphisms C]

namespace short_complex

instance [has_zero_object C] : inhabited (short_complex C) :=
⟨short_complex.mk (0 : 0 ⟶ 0) (0 : 0 ⟶ 0) comp_zero⟩

attribute [simp, reassoc] zero

/-- Morphisms of short complexes are the commutative diagrams of the obvious shape. -/
@[ext]
structure hom (S₁ S₂ : short_complex C) :=
(τ₁ : S₁.X₁ ⟶ S₂.X₁)
(τ₂ : S₁.X₂ ⟶ S₂.X₂)
(τ₃ : S₁.X₃ ⟶ S₂.X₃)
(comm₁₂ : τ₁ ≫ S₂.f = S₁.f ≫ τ₂)
(comm₂₃ : τ₂ ≫ S₂.g = S₁.g ≫ τ₃)

attribute [reassoc] hom.comm₁₂ hom.comm₂₃

variables (S : short_complex C) {S₁ S₂ S₃ : short_complex C}

/-- The identity morphism of a short complex. -/
@[simps]
def hom.id : hom S S := ⟨𝟙 _, 𝟙 _, 𝟙 _, by simp, by simp⟩

instance : inhabited (hom S S) := ⟨hom.id S⟩

/-- The composition of morphisms of short complexes. -/
@[simps]
def hom.comp (φ₁₂ : hom S₁ S₂) (φ₂₃ : hom S₂ S₃) : hom S₁ S₃ :=
⟨φ₁₂.τ₁ ≫ φ₂₃.τ₁, φ₁₂.τ₂ ≫ φ₂₃.τ₂, φ₁₂.τ₃ ≫ φ₂₃.τ₃,
  by simp only [assoc, hom.comm₁₂, hom.comm₁₂_assoc],
  by simp only [assoc, hom.comm₂₃, hom.comm₂₃_assoc]⟩

instance : category (short_complex C) :=
{ hom := hom,
  id := hom.id,
  comp := λ S₁ S₂ S₃, hom.comp, }

@[simp] lemma id_τ₁ : hom.τ₁ (𝟙 S) = 𝟙 _ := rfl
@[simp] lemma id_τ₂ : hom.τ₂ (𝟙 S) = 𝟙 _ := rfl
@[simp] lemma id_τ₃ : hom.τ₃ (𝟙 S) = 𝟙 _ := rfl
@[simp] lemma comp_τ₁ (φ₁₂ : S₁ ⟶ S₂) (φ₂₃ : S₂ ⟶ S₃) : (φ₁₂ ≫ φ₂₃).τ₁ = φ₁₂.τ₁ ≫ φ₂₃.τ₁ := rfl
@[simp] lemma comp_τ₂ (φ₁₂ : S₁ ⟶ S₂) (φ₂₃ : S₂ ⟶ S₃) : (φ₁₂ ≫ φ₂₃).τ₂ = φ₁₂.τ₂ ≫ φ₂₃.τ₂ := rfl
@[simp] lemma comp_τ₃ (φ₁₂ : S₁ ⟶ S₂) (φ₂₃ : S₂ ⟶ S₃) : (φ₁₂ ≫ φ₂₃).τ₃ = φ₁₂.τ₃ ≫ φ₂₃.τ₃ := rfl

/-- The first projection functor `short_complex C ⥤ C`. -/
@[simps]
def π₁ : short_complex C ⥤ C :=
{ obj := λ S, S.X₁,
  map := λ S₁ S₂ f, f.τ₁, }

/-- The second projection functor `short_complex C ⥤ C`. -/
@[simps]
def π₂ : short_complex C ⥤ C :=
{ obj := λ S, S.X₂,
  map := λ S₁ S₂ f, f.τ₂, }

/-- The third projection functor `short_complex C ⥤ C`. -/
@[simps]
def π₃ : short_complex C ⥤ C :=
{ obj := λ S, S.X₃,
  map := λ S₁ S₂ f, f.τ₃, }

instance (f : S₁ ⟶ S₂) [is_iso f] : is_iso f.τ₁ :=
by { change is_iso (π₁.map_iso (as_iso f)).hom, apply_instance, }

instance (f : S₁ ⟶ S₂) [is_iso f] : is_iso f.τ₂ :=
by { change is_iso (π₂.map_iso (as_iso f)).hom, apply_instance, }

instance (f : S₁ ⟶ S₂) [is_iso f] : is_iso f.τ₃ :=
by { change is_iso (π₃.map_iso (as_iso f)).hom, apply_instance, }

variables {C D}

@[simps]
def _root_.category_theory.functor.map_short_complex
  [has_zero_morphisms D] (F : C ⥤ D) [F.preserves_zero_morphisms] : short_complex C ⥤ short_complex D :=
{ obj := λ S, short_complex.mk (F.map S.f) (F.map S.g)
    (by rw [← F.map_comp, S.zero, F.map_zero]),
  map := λ S₁ S₂ φ, short_complex.hom.mk (F.map φ.τ₁) (F.map φ.τ₂) (F.map φ.τ₃)
    (by { dsimp, simp only [← F.map_comp, φ.comm₁₂], })
    (by { dsimp, simp only [← F.map_comp, φ.comm₂₃], }), }

@[simps]
def map [has_zero_morphisms D] (F : C ⥤ D) [F.preserves_zero_morphisms] : short_complex D :=
F.map_short_complex.obj S

/-- A constructor for isomorphisms in the category `short_complex C`-/
@[simps]
def mk_iso (e₁ : S₁.X₁ ≅ S₂.X₁) (e₂ : S₁.X₂ ≅ S₂.X₂) (e₃ : S₁.X₃ ≅ S₂.X₃)
  (comm₁₂ : e₁.hom ≫ S₂.f = S₁.f ≫ e₂.hom) (comm₂₃ : e₂.hom ≫ S₂.g = S₁.g ≫ e₃.hom) :
  S₁ ≅ S₂ :=
{ hom := hom.mk e₁.hom e₂.hom e₃.hom comm₁₂ comm₂₃,
  inv := hom.mk e₁.inv e₂.inv e₃.inv
    (by simp only [← cancel_mono e₂.hom, assoc, e₂.inv_hom_id, comp_id,
      ← comm₁₂, e₁.inv_hom_id_assoc])
    (by simp only [← cancel_mono e₃.hom, assoc, e₃.inv_hom_id, comp_id,
      ← comm₂₃, e₂.inv_hom_id_assoc]), }

/-- The opposite short_complex in `Cᵒᵖ` associated to a short complex in `C`. -/
@[simps]
def op : short_complex Cᵒᵖ :=
mk S.g.op S.f.op (by simpa only [← op_comp, S.zero])

/-- The opposite morphism in `short_complex Cᵒᵖ` associated to a morphism in `short_complex C` -/
@[simps]
def op_map (φ : S₁ ⟶ S₂) : S₂.op ⟶ S₁.op :=
⟨φ.τ₃.op, φ.τ₂.op, φ.τ₁.op,
  (by { dsimp, simp only [← op_comp, φ.comm₂₃], }),
  (by { dsimp, simp only [← op_comp, φ.comm₁₂], })⟩

/-- The short_complex in `C` associated to a short complex in `Cᵒᵖ`. -/
@[simps]
def unop (S : short_complex Cᵒᵖ) : short_complex C :=
mk S.g.unop S.f.unop (by simpa only [← unop_comp, S.zero])

/-- The morphism in `short_complex C` associated to a morphism in `short_complex Cᵒᵖ` -/
@[simps]
def unop'_map {S₁ S₂ : short_complex Cᵒᵖ} (φ : S₁ ⟶ S₂) : S₂.unop ⟶ S₁.unop :=
⟨φ.τ₃.unop, φ.τ₂.unop, φ.τ₁.unop,
  (by { dsimp, simp only [← unop_comp, φ.comm₂₃], }),
  (by { dsimp, simp only [← unop_comp, φ.comm₁₂], })⟩

/-- The morphism in `short_complex C` associated to a morphism in `short_complex Cᵒᵖ` -/
@[simps]
def unop_map {S₁ S₂ : short_complex C} (φ : S₁.op ⟶ S₂.op) : S₂ ⟶ S₁ :=
⟨φ.τ₃.unop, φ.τ₂.unop, φ.τ₁.unop, quiver.hom.op_inj φ.comm₂₃.symm,
  quiver.hom.op_inj φ.comm₁₂.symm⟩

/-- The obvious isomorphism `S.op.unop ≅ S` for `S : short_complex C`. -/
@[simps]
def op_unop : S.op.unop ≅ S :=
mk_iso (iso.refl _) (iso.refl _) (iso.refl _) (by tidy) (by tidy)

/-- The obvious isomorphism `S.unop.op ≅ S` for `S : short_complex Cᵒᵖ`. -/
@[simps]
def unop_op (S : short_complex Cᵒᵖ) : S.unop.op ≅ S :=
mk_iso (iso.refl _) (iso.refl _) (iso.refl _) (by tidy) (by tidy)

variable (C)

/-- The obvious functor `(short_complex C)ᵒᵖ ⥤ short_complex Cᵒᵖ`. -/
@[simps]
def op_functor : (short_complex C)ᵒᵖ ⥤ short_complex Cᵒᵖ :=
{ obj := λ S, (opposite.unop S).op,
  map := λ S₁ S₂ φ, op_map φ.unop, }

/-- The obvious functor `short_complex Cᵒᵖ ⥤ (short_complex C)ᵒᵖ`. -/
@[simps]
def unop_functor : short_complex Cᵒᵖ ⥤ (short_complex C)ᵒᵖ :=
{ obj := λ S, opposite.op (unop S),
  map := λ S₁ S₂ φ, (unop'_map φ).op, }

/-- The obvious equivalence of categories `(short_complex C)ᵒᵖ ≌ short_complex Cᵒᵖ`. -/
def op_equiv : (short_complex C)ᵒᵖ ≌ short_complex Cᵒᵖ :=
{ functor := op_functor C,
  inverse := unop_functor C,
  unit_iso := nat_iso.of_components (λ S, (op_unop (opposite.unop S)).op)
    (λ S₁ S₂ f, quiver.hom.unop_inj (by tidy)),
  counit_iso := nat_iso.of_components (unop_op) (by tidy), }

variables (S₁ S₂) {C}

/-- The zero morphism between two short complexes. -/
@[simps]
def hom.zero : S₁ ⟶ S₂ :=
⟨0, 0, 0, by simp, by simp⟩

@[simps]
instance : has_zero (S₁ ⟶ S₂) := ⟨hom.zero _ _⟩

instance : has_zero_morphisms (short_complex C) := { }

@[nolint has_nonempty_instance]
structure left_homology_data :=
(K H : C)
(i : K ⟶ S.X₂)
(π : K ⟶ H)
(hi₀ : i ≫ S.g = 0)
(hi : is_limit (kernel_fork.of_ι i hi₀))
(hπ₀ : hi.lift (kernel_fork.of_ι _ S.zero) ≫ π = 0)
(hπ : is_colimit (cokernel_cofork.of_π π hπ₀))

namespace left_homology_data

@[simp]
def of_ker_of_coker [has_kernel S.g] [has_cokernel (kernel.lift₀ S.g S.f S.zero)] :
  S.left_homology_data :=
{ K := kernel S.g,
  H := cokernel (kernel.lift₀ S.g S.f S.zero),
  i := kernel.ι _,
  π := cokernel.π _,
  hi₀ := kernel.condition _,
  hi := kernel_is_kernel _,
  hπ₀ := cokernel.condition _,
  hπ := cokernel_is_cokernel _, }

attribute [simp, reassoc] hi₀ hπ₀
variables {S} (h : left_homology_data S) {A : C}

instance : mono h.i :=
⟨λ Y l₁ l₂, fork.is_limit.hom_ext h.hi⟩

instance : epi h.π :=
⟨λ Y l₁ l₂, cofork.is_colimit.hom_ext h.hπ⟩

def lift_K (k : A ⟶ S.X₂) (hk : k ≫ S.g = 0) : A ⟶ h.K :=
h.hi.lift (kernel_fork.of_ι k hk)

@[simp, reassoc]
lemma lift_K_i (k : A ⟶ S.X₂) (hk : k ≫ S.g = 0) :
  h.lift_K k hk ≫ h.i = k :=
h.hi.fac _ walking_parallel_pair.zero

@[simp]
def lift_H (k : A ⟶ S.X₂) (hk : k ≫ S.g = 0) : A ⟶ h.H :=
  h.lift_K k hk ≫ h.π

/-- The morphism `S.X₁ ⟶ h.K` induced by `S.f : S.X₁ ⟶ S.X₂` and the fact that
`h.K` is a kernel of `S.g : S.X₂ ⟶ S.X₃`. -/
def f' : S.X₁ ⟶ h.K := h.lift_K S.f S.zero

@[simp, reassoc]
lemma f'_i : h.f' ≫ h.i = S.f :=
lift_K_i _ _ _

@[simp, reassoc]
lemma f'_π : h.f' ≫ h.π = 0 := h.hπ₀

/-- For `h : homology_ful_data S`, this is a restatement of `h.hπ`, saying that
`π : h.K ⟶ h.H` is a cokernel of `h.f' : S.X₁ ⟶ h.K`. -/
@[simp]
def hπ' : is_colimit (cokernel_cofork.of_π h.π h.f'_π) := h.hπ

def desc_H (k : h.K ⟶ A) (hk : h.f' ≫ k = 0) :
  h.H ⟶ A :=
h.hπ.desc (cokernel_cofork.of_π k hk)

@[simp, reassoc]
lemma π_desc_H (k : h.K ⟶ A) (hk : h.f' ≫ k = 0) :
  h.π ≫ h.desc_H k hk = k :=
h.hπ.fac (cokernel_cofork.of_π k hk) walking_parallel_pair.one

variable (S)

@[simp]
def of_colimit_cokernel_cofork (hg : S.g = 0) (c : cokernel_cofork S.f) (hc : is_colimit c) :
  S.left_homology_data :=
{ K := S.X₂,
  H := c.X,
  i := 𝟙 _,
  π := c.π,
  hi₀ := by rw [id_comp, hg],
  hi := kernel_zero _ hg,
  hπ₀ := cokernel_cofork.condition _,
  hπ := is_colimit.of_iso_colimit hc (cofork.ext (iso.refl _) (by tidy)), }

@[simp]
def of_has_cokernel [has_cokernel S.f] (hg : S.g = 0) : S.left_homology_data :=
of_colimit_cokernel_cofork S hg _ (cokernel_is_cokernel _)

@[simp]
def of_limit_kernel_fork (hf : S.f = 0) (c : kernel_fork S.g) (hc : is_limit c) :
  S.left_homology_data :=
{ K := c.X,
  H := c.X,
  i := c.ι,
  π := 𝟙 _,
  hi₀ := kernel_fork.condition _,
  hi := is_limit.of_iso_limit hc (fork.ext (iso.refl _) (by tidy)),
  hπ₀ := fork.is_limit.hom_ext hc begin
    dsimp, simp only [hf, comp_id, fork.is_limit.lift_ι, kernel_fork.ι_of_ι, zero_comp],
  end,
  hπ := cokernel_zero _ begin
    apply fork.is_limit.hom_ext hc,
    dsimp,
    simp only [hf, comp_id, fork.is_limit.lift_ι, kernel_fork.ι_of_ι, zero_comp],
  end, }

@[simp]
def of_has_kernel [has_kernel S.g] (hf : S.f = 0) : S.left_homology_data :=
of_limit_kernel_fork S hf _ (kernel_is_kernel _)

@[simp]
def of_zeros (hf : S.f = 0) (hg : S.g = 0) :
  S.left_homology_data :=
{ K := S.X₂,
  H := S.X₂,
  i := 𝟙 _,
  π := 𝟙 _,
  hi₀ := by rw [id_comp, hg],
  hi := kernel_zero _ hg,
  hπ₀ := by { dsimp, rw [comp_id, hf], },
  hπ := cokernel_zero _ hf, }

end left_homology_data

class has_left_homology : Prop :=
(cond : nonempty S.left_homology_data)

def some_left_homology_data [has_left_homology S] :
  S.left_homology_data := has_left_homology.cond.some

variable {S}

lemma has_left_homology.mk' (h : S.left_homology_data) : has_left_homology S :=
⟨nonempty.intro h⟩

@[priority 100]
instance has_left_homology_of_ker_of_coker
  [has_kernel S.g] [has_cokernel (kernel.lift₀ S.g S.f S.zero)] :
  S.has_left_homology := has_left_homology.mk' (left_homology_data.of_ker_of_coker S)

instance has_left_homology_of_has_cokernel {X Y : C} (f : X ⟶ Y) (Z : C)
  [has_cokernel f] :
  (short_complex.mk f (0 : Y ⟶ Z) comp_zero).has_left_homology :=
has_left_homology.mk' (left_homology_data.of_has_cokernel _ rfl)

instance has_left_homology_of_has_kernel {Y Z : C} (g : Y ⟶ Z) (X : C)
  [has_kernel g] :
  (short_complex.mk (0 : X ⟶ Y) g zero_comp).has_left_homology :=
has_left_homology.mk' (left_homology_data.of_has_kernel _ rfl)

instance has_left_homology_of_zeros (X Y Z : C) :
  (short_complex.mk (0 : X ⟶ Y) (0 : Y ⟶ Z) zero_comp).has_left_homology :=
has_left_homology.mk' (left_homology_data.of_zeros _ rfl rfl)

section

variables {S₁ S₂} (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data)

structure left_homology_map_data :=
(φK : h₁.K ⟶ h₂.K)
(φH : h₁.H ⟶ h₂.H)
(commi : h₁.i ≫ φ.τ₂ = φK ≫ h₂.i)
(commf' : h₁.f' ≫ φK = φ.τ₁ ≫ h₂.f')
(commπ : h₁.π ≫ φH = φK ≫ h₂.π)

namespace left_homology_map_data

attribute [reassoc] commi commf' commπ

@[simps]
def id (h : S.left_homology_data) : left_homology_map_data (𝟙 S) h h :=
{ φK := 𝟙 _,
  φH := 𝟙 _,
  commi := by simp only [id_τ₂, comp_id, id_comp],
  commf' := by simp only [comp_id, id_τ₁, id_comp],
  commπ := by simp only [comp_id, id_comp], }

@[simps]
def comp {φ : S₁ ⟶ S₂} {φ' : S₂ ⟶ S₃} {h₁ : S₁.left_homology_data}
  {h₂ : S₂.left_homology_data} {h₃ : S₃.left_homology_data}
  (ψ : left_homology_map_data φ h₁ h₂) (ψ' : left_homology_map_data φ' h₂ h₃) :
  left_homology_map_data (φ ≫ φ') h₁ h₃ :=
{ φK := ψ.φK ≫ ψ'.φK,
  φH := ψ.φH ≫ ψ'.φH,
  commi := by { simp only [assoc, comp_τ₂, ψ.commi_assoc, ψ'.commi], },
  commf' := by { simp only [comp_τ₁, assoc, ψ.commf'_assoc, ψ'.commf'], },
  commπ := by { simp only [assoc, ψ.commπ_assoc, ψ'.commπ], }, }

instance : subsingleton (left_homology_map_data φ h₁ h₂) :=
⟨begin
  rintros ⟨φK₁, φH₁, commi₁, commf'₁, commπ₁⟩ ⟨φK₂, φH₂, commi₂, commf'₂, commπ₂⟩,
  have hK : φK₁ = φK₂ := by rw [← cancel_mono h₂.i, ← commi₁, ← commi₂],
  have hH : φH₁ = φH₂ := by rw [← cancel_epi h₁.π, commπ₁, commπ₂, hK],
  simp only,
  split; assumption,
end⟩

instance : inhabited (left_homology_map_data φ h₁ h₂) :=
⟨begin
  let φK : h₁.K ⟶ h₂.K := h₂.lift_K (h₁.i ≫ φ.τ₂)
    (by rw [assoc, φ.comm₂₃, h₁.hi₀_assoc, zero_comp]),
  have commi : h₁.i ≫ φ.τ₂ = φK ≫ h₂.i := by rw left_homology_data.lift_K_i,
  have commf' : h₁.f' ≫ φK = φ.τ₁ ≫ h₂.f',
  { simp only [← cancel_mono h₂.i, assoc, left_homology_data.lift_K_i,
      left_homology_data.f'_i_assoc, left_homology_data.f'_i, φ.comm₁₂], },
  let φH : h₁.H ⟶ h₂.H := h₁.desc_H (φK ≫ h₂.π)
    (by rw [reassoc_of commf', h₂.f'_π, comp_zero]),
  have commπ : h₁.π ≫ φH = φK ≫ h₂.π := left_homology_data.π_desc_H _ _ _,
  exact ⟨φK, φH, commi, commf', commπ⟩,
end⟩

instance : unique (left_homology_map_data φ h₁ h₂) := unique.mk' _

def some : left_homology_map_data φ h₁ h₂ := default

variables {φ h₁ h₂}

lemma congr_φH {γ₁ γ₂ : left_homology_map_data φ h₁ h₂} (eq : γ₁ = γ₂) :
  γ₁.φH = γ₂.φH := by rw eq
lemma congr_φK {γ₁ γ₂ : left_homology_map_data φ h₁ h₂} (eq : γ₁ = γ₂) :
  γ₁.φK = γ₂.φK := by rw eq

end left_homology_map_data

end

variable (S)

def left_homology [has_left_homology S] : C := S.some_left_homology_data.H
def cycles [has_left_homology S] : C := S.some_left_homology_data.K
def left_homology_π [has_left_homology S] : S.cycles ⟶ S.left_homology :=
  S.some_left_homology_data.π
def cycles_i [has_left_homology S] : S.cycles ⟶ S.X₂ := S.some_left_homology_data.i

variables {S S₁ S₂ S₃}

def left_homology_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  h₁.H ⟶ h₂.H := (left_homology_map_data.some φ _ _).φH

def cycles_map' (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  h₁.K ⟶ h₂.K := (left_homology_map_data.some φ _ _).φK

@[simp, reassoc]
lemma cycles_map'_i (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  cycles_map' φ h₁ h₂ ≫ h₂.i = h₁.i ≫ φ.τ₂ :=
by { symmetry, apply left_homology_map_data.commi, }

@[reassoc]
lemma left_homology_π_naturality' (φ : S₁ ⟶ S₂)
  (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  cycles_map' φ h₁ h₂ ≫ h₂.π = h₁.π ≫ left_homology_map' φ h₁ h₂ :=
by { symmetry, apply left_homology_map_data.commπ, }

def left_homology_map [has_left_homology S₁] [has_left_homology S₂]
  (φ : S₁ ⟶ S₂) : S₁.left_homology ⟶ S₂.left_homology :=
left_homology_map' φ _ _

def cycles_map [has_left_homology S₁] [has_left_homology S₂]
  (φ : S₁ ⟶ S₂) : S₁.cycles ⟶ S₂.cycles :=
cycles_map' φ _ _

@[simp, reassoc]
lemma cycles_map_i (φ : S₁ ⟶ S₂) [S₁.has_left_homology] [S₂.has_left_homology] :
  cycles_map φ ≫ S₂.cycles_i = S₁.cycles_i ≫ φ.τ₂ :=
cycles_map'_i _ _ _

@[reassoc]
lemma left_homology_π_naturality [has_left_homology S₁] [has_left_homology S₂]
  (φ : S₁ ⟶ S₂) : cycles_map φ ≫ S₂.left_homology_π = S₁.left_homology_π ≫ left_homology_map φ :=
left_homology_π_naturality' _ _ _

@[simp]
lemma left_homology_map'_id (h : S.left_homology_data) :
  left_homology_map' (𝟙 S) h h = 𝟙 _ :=
left_homology_map_data.congr_φH (subsingleton.elim  _ (left_homology_map_data.id _))

@[simp]
lemma cycles_map'_id (h : S.left_homology_data) :
  cycles_map' (𝟙 S) h h = 𝟙 _ :=
left_homology_map_data.congr_φK (subsingleton.elim  _ (left_homology_map_data.id _))

variable (S)

@[simp]
lemma left_homology_map_id [has_left_homology S] :
  left_homology_map (𝟙 S) = 𝟙 _ :=
left_homology_map'_id _

@[simp]
lemma cycles_map_id [has_left_homology S] :
  cycles_map (𝟙 S) = 𝟙 _ :=
cycles_map'_id _

lemma left_homology_map'_comp (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃)
  (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) (h₃ : S₃.left_homology_data) :
  left_homology_map' (φ₁ ≫ φ₂) h₁ h₃ = left_homology_map' φ₁ h₁ h₂ ≫
    left_homology_map' φ₂ h₂ h₃ :=
left_homology_map_data.congr_φH
  (subsingleton.elim _ (((left_homology_map_data.some φ₁ _ _).comp
    (left_homology_map_data.some φ₂ _ _))))

lemma cycles_map'_comp (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃)
  (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) (h₃ : S₃.left_homology_data) :
  cycles_map' (φ₁ ≫ φ₂) h₁ h₃ = cycles_map' φ₁ h₁ h₂ ≫
    cycles_map' φ₂ h₂ h₃ :=
left_homology_map_data.congr_φK
  (subsingleton.elim _ (((left_homology_map_data.some φ₁ _ _).comp
    (left_homology_map_data.some φ₂ _ _))))

@[simp]
lemma left_homology_map_comp [has_left_homology S₁] [has_left_homology S₂] [has_left_homology S₃]
  (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃) :
  left_homology_map (φ₁ ≫ φ₂) = left_homology_map φ₁ ≫ left_homology_map φ₂ :=
left_homology_map'_comp _ _ _ _ _

@[simp]
lemma cycles_map_comp [has_left_homology S₁] [has_left_homology S₂] [has_left_homology S₃]
  (φ₁ : S₁ ⟶ S₂) (φ₂ : S₂ ⟶ S₃) :
  cycles_map (φ₁ ≫ φ₂) = cycles_map φ₁ ≫ cycles_map φ₂ :=
cycles_map'_comp _ _ _ _ _

@[simps]
def left_homology_map_iso' (e : S₁ ≅ S₂) (h₁ : S₁.left_homology_data)
  (h₂ : S₂.left_homology_data) : h₁.H ≅ h₂.H :=
{ hom := left_homology_map' e.hom h₁ h₂,
  inv := left_homology_map' e.inv h₂ h₁,
  hom_inv_id' := by rw [← left_homology_map'_comp, e.hom_inv_id, left_homology_map'_id],
  inv_hom_id' := by rw [← left_homology_map'_comp, e.inv_hom_id, left_homology_map'_id], }

instance is_iso_left_homology_map'_of_iso (φ : S₁ ⟶ S₂) [is_iso φ]
  (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data) :
  is_iso (left_homology_map' φ h₁ h₂) :=
by { change is_iso (left_homology_map_iso' (as_iso φ) h₁ h₂).hom, apply_instance, }

@[simps]
def cycles_map_iso' (e : S₁ ≅ S₂) (h₁ : S₁.left_homology_data)
  (h₂ : S₂.left_homology_data) : h₁.K ≅ h₂.K :=
{ hom := cycles_map' e.hom h₁ h₂,
  inv := cycles_map' e.inv h₂ h₁,
  hom_inv_id' := by rw [← cycles_map'_comp, e.hom_inv_id, cycles_map'_id],
  inv_hom_id' := by rw [← cycles_map'_comp, e.inv_hom_id, cycles_map'_id], }

@[simps]
def left_homology_map_iso (e : S₁ ≅ S₂) [S₁.has_left_homology]
  [S₂.has_left_homology] : S₁.left_homology ≅ S₂.left_homology :=
{ hom := left_homology_map e.hom,
  inv := left_homology_map e.inv,
  hom_inv_id' := by rw [← left_homology_map_comp, e.hom_inv_id, left_homology_map_id],
  inv_hom_id' := by rw [← left_homology_map_comp, e.inv_hom_id, left_homology_map_id], }

instance is_iso_left_homology_map_of_iso (φ : S₁ ⟶ S₂) [is_iso φ] [S₁.has_left_homology]
  [S₂.has_left_homology] :
  is_iso (left_homology_map φ) :=
by { change is_iso (left_homology_map_iso (as_iso φ)).hom, apply_instance, }

@[simps]
def cycles_map_iso (e : S₁ ≅ S₂) [S₁.has_left_homology]
  [S₂.has_left_homology] : S₁.cycles ≅ S₂.cycles :=
{ hom := cycles_map e.hom,
  inv := cycles_map e.inv,
  hom_inv_id' := by rw [← cycles_map_comp, e.hom_inv_id, cycles_map_id],
  inv_hom_id' := by rw [← cycles_map_comp, e.inv_hom_id, cycles_map_id], }

variable {S}

def left_homology_data.left_homology_iso (h₁ : S.left_homology_data) [S.has_left_homology] :
  S.left_homology ≅ h₁.H := left_homology_map_iso' (iso.refl _) _ _

def left_homology_data.cycles_iso (h₁ : S.left_homology_data) [S.has_left_homology] :
  S.cycles ≅ h₁.K := cycles_map_iso' (iso.refl _) _ _

namespace left_homology_map_data

variables {φ : S₁ ⟶ S₂} {h₁ : S₁.left_homology_data} {h₂ : S₂.left_homology_data}
  (γ : left_homology_map_data φ h₁ h₂)

lemma left_homology_map'_eq : left_homology_map' φ h₁ h₂ = γ.φH :=
left_homology_map_data.congr_φH (subsingleton.elim _ _)

lemma cycles_map'_eq : cycles_map' φ h₁ h₂ = γ.φK :=
left_homology_map_data.congr_φK (subsingleton.elim _ _)

lemma left_homology_map_eq [S₁.has_left_homology] [S₂.has_left_homology] :
  left_homology_map φ = h₁.left_homology_iso.hom ≫ γ.φH ≫ h₂.left_homology_iso.inv :=
begin
  dsimp [left_homology_data.left_homology_iso, left_homology_map_iso'],
  rw [← γ.left_homology_map'_eq, ← left_homology_map'_comp, ← left_homology_map'_comp, id_comp, comp_id],
  refl,
end

lemma cycles_map_eq [S₁.has_left_homology] [S₂.has_left_homology] :
  cycles_map φ = h₁.cycles_iso.hom ≫ γ.φK ≫ h₂.cycles_iso.inv :=
begin
  dsimp [left_homology_data.cycles_iso, cycles_map_iso'],
  rw [← γ.cycles_map'_eq, ← cycles_map'_comp, ← cycles_map'_comp, id_comp, comp_id],
  refl,
end

lemma left_homology_map_comm [S₁.has_left_homology] [S₂.has_left_homology] :
  left_homology_map φ ≫ h₂.left_homology_iso.hom = h₁.left_homology_iso.hom ≫ γ.φH :=
by simp only [γ.left_homology_map_eq, assoc, iso.inv_hom_id, comp_id]

lemma cycles_map_comm [S₁.has_left_homology] [S₂.has_left_homology] :
  cycles_map φ ≫ h₂.cycles_iso.hom = h₁.cycles_iso.hom ≫ γ.φK :=
by simp only [γ.cycles_map_eq, assoc, iso.inv_hom_id, comp_id]

end left_homology_map_data

variable (C)
/-- We shall say that a category with left homology is a category for which
all short complexes have left homology. -/
abbreviation _root_.category_with_left_homology := ∀ (S : short_complex C), S.has_left_homology

@[simps]
def left_homology_functor [category_with_left_homology C] :
  short_complex C ⥤ C :=
{ obj := λ S, S.left_homology,
  map := λ S₁ S₂, left_homology_map, }

@[simps]
def cycles_functor [category_with_left_homology C] :
  short_complex C ⥤ C :=
{ obj := λ S, S.cycles,
  map := λ S₁ S₂, cycles_map, }

@[simps]
def left_homology_π_nat_trans [category_with_left_homology C] :
  cycles_functor C ⟶ left_homology_functor C :=
{ app := λ S, left_homology_π S,
  naturality' := λ S₁ S₂, left_homology_π_naturality, }

@[simps]
def cycles_i_nat_trans [category_with_left_homology C] :
  cycles_functor C ⟶ short_complex.π₂ :=
{ app := λ S, cycles_i S, }

namespace left_homology_data

variable {C}

@[simp]
def of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : left_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : left_homology_data S₂ :=
begin
  let i : h.K ⟶ S₂.X₂ := h.i ≫ φ.τ₂,
  have hi₀ : i ≫ S₂.g = 0 := by simp only [assoc, φ.comm₂₃, h.hi₀_assoc, zero_comp],
  have hi : is_limit (kernel_fork.of_ι i hi₀) := kernel_fork.is_limit.of_ι _ _
    (λ A x hx, h.lift_K (x ≫ inv φ.τ₂) (by simp only [assoc, ← cancel_mono φ.τ₃,
      zero_comp, ← φ.comm₂₃, is_iso.inv_hom_id_assoc, hx]))
    (λ A x hx, by simp only [assoc, lift_K_i_assoc, is_iso.inv_hom_id, comp_id])
    (λ A x hx b hx, by simp only [← cancel_mono h.i, ← cancel_mono φ.τ₂,
        assoc, lift_K_i, is_iso.inv_hom_id, comp_id, hx]),
  let f' := hi.lift (kernel_fork.of_ι S₂.f S₂.zero),
  have hf' : φ.τ₁ ≫ f' = h.f',
  { have eq := @fork.is_limit.lift_ι _ _ _ _ _ _ _ ((kernel_fork.of_ι S₂.f S₂.zero)) hi,
    simp only [kernel_fork.ι_of_ι] at eq,
    simp only [← cancel_mono h.i, ← cancel_mono φ.τ₂, assoc, eq, f'_i_assoc, φ.comm₁₂], },
  have hπ₀ : f' ≫ h.π = 0,
  { rw [← cancel_epi φ.τ₁, comp_zero, reassoc_of hf', h.f'_π], },
  have hπ : is_colimit (cokernel_cofork.of_π h.π hπ₀) := cokernel_cofork.is_colimit.of_π _ _
    (λ A x hx, h.desc_H x (by rw [← hf', assoc, hx, comp_zero]))
    (λ A x hx, π_desc_H _ _ _)
    (λ A x hx b hb, by simp only [← cancel_epi h.π, π_desc_H, hb]),
  exact ⟨h.K, h.H, i, h.π, hi₀, hi, hπ₀, hπ⟩,
end

@[simp]
lemma of_epi_of_is_iso_of_mono_i (φ : S₁ ⟶ S₂) (h : left_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : (of_epi_of_is_iso_of_mono φ h).i = h.i ≫ φ.τ₂ := rfl

@[simp]
lemma of_epi_of_is_iso_of_mono_π (φ : S₁ ⟶ S₂) (h : left_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : (of_epi_of_is_iso_of_mono φ h).π = h.π := rfl

@[simp]
lemma of_epi_of_is_iso_of_mono_τ₁_f' (φ : S₁ ⟶ S₂) (h : left_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : φ.τ₁ ≫ (of_epi_of_is_iso_of_mono φ h).f' = h.f' :=
by rw [← cancel_mono (of_epi_of_is_iso_of_mono φ h).i, assoc, f'_i,
    of_epi_of_is_iso_of_mono_i, f'_i_assoc, φ.comm₁₂]

def of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) (h : left_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : left_homology_data S₁ :=
begin
  let i : h.K ⟶ S₁.X₂ := h.i ≫ inv φ.τ₂,
  have hi₀ : i ≫ S₁.g = 0 := by simp only [assoc, ← cancel_mono φ.τ₃, zero_comp,
    ← φ.comm₂₃, is_iso.inv_hom_id_assoc, h.hi₀],
  have hi : is_limit (kernel_fork.of_ι i hi₀) := kernel_fork.is_limit.of_ι _ _
    (λ A x hx, h.lift_K (x ≫ φ.τ₂) (by rw [assoc, φ.comm₂₃, reassoc_of hx, zero_comp]))
    (λ A x hx, by simp only [assoc, lift_K_i_assoc, is_iso.hom_inv_id, comp_id])
    (λ A x hx b hb, by simp only [← cancel_mono h.i, lift_K_i, ← hb,
      assoc, is_iso.inv_hom_id, comp_id]),
  let f' := hi.lift (kernel_fork.of_ι S₁.f S₁.zero),
  have hf' : f' ≫ i = S₁.f := by simpa only [kernel_fork.ι_of_ι]
    using @fork.is_limit.lift_ι _ _ _ _ _ _ _ ((kernel_fork.of_ι S₁.f S₁.zero)) hi,
  have hf'' : f' = φ.τ₁ ≫ h.f',
  { simpa only [← cancel_mono h.i, ← cancel_mono (inv φ.τ₂), assoc, f'_i_assoc, φ.comm₁₂_assoc,
      is_iso.hom_inv_id, comp_id] using fork.is_limit.lift_ι _, },
  have hπ₀ : f' ≫ h.π = 0 := by simp only [hf'', assoc, f'_π, comp_zero],
  have hπ : is_colimit (cokernel_cofork.of_π h.π hπ₀) := cokernel_cofork.is_colimit.of_π _ _
    (λ A x hx, h.desc_H x (by rw [← cancel_epi φ.τ₁, ← reassoc_of hf'', hx, comp_zero]))
    (λ A x hx, π_desc_H _ _ _)
    (λ A x hx b hx, by simp only [← cancel_epi h.π, π_desc_H, hx]),
  exact ⟨h.K, h.H, i, h.π, hi₀, hi, hπ₀, hπ⟩,
end

@[simp]
lemma of_epi_of_is_iso_of_mono'_i (φ : S₁ ⟶ S₂) (h : left_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : (of_epi_of_is_iso_of_mono' φ h).i = h.i ≫ inv φ.τ₂ := rfl

@[simp]
lemma of_epi_of_is_iso_of_mono'_π (φ : S₁ ⟶ S₂) (h : left_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : (of_epi_of_is_iso_of_mono' φ h).π = h.π := rfl

@[simp]
lemma of_epi_of_is_iso_of_mono'_f' (φ : S₁ ⟶ S₂) (h : left_homology_data S₂)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  (of_epi_of_is_iso_of_mono' φ h).f' = φ.τ₁ ≫ h.f' :=
by rw [← cancel_mono (of_epi_of_is_iso_of_mono' φ h).i, f'_i, of_epi_of_is_iso_of_mono'_i,
    assoc, f'_i_assoc, φ.comm₁₂_assoc, is_iso.hom_inv_id, comp_id]

def of_iso (e : S₁ ≅ S₂) (h₁ : left_homology_data S₁) : left_homology_data S₂ :=
h₁.of_epi_of_is_iso_of_mono e.hom

end left_homology_data

variables {C}

lemma has_left_homology_of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) [has_left_homology S₁]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_left_homology S₂ :=
has_left_homology.mk' (left_homology_data.of_epi_of_is_iso_of_mono φ S₁.some_left_homology_data)

lemma has_left_homology_of_epi_of_is_iso_of_mono' (φ : S₁ ⟶ S₂) [has_left_homology S₂]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] : has_left_homology S₁ :=
has_left_homology.mk' (left_homology_data.of_epi_of_is_iso_of_mono' φ S₂.some_left_homology_data)

lemma has_left_homology_of_iso {S₁ S₂ : short_complex C}
  (e : S₁ ≅ S₂) [has_left_homology S₁] : has_left_homology S₂ :=
has_left_homology_of_epi_of_is_iso_of_mono e.hom

namespace left_homology_map_data

@[simps]
def of_epi_of_is_iso_of_mono (φ : S₁ ⟶ S₂) (h : left_homology_data S₁)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
    left_homology_map_data φ h (left_homology_data.of_epi_of_is_iso_of_mono φ h) :=
{ φK := 𝟙 _,
  φH := 𝟙 _,
  commi := by { dsimp, rw id_comp, },
  commf' := by rw [left_homology_data.of_epi_of_is_iso_of_mono_τ₁_f' φ h, comp_id],
  commπ := by { simp only [id_comp, comp_id, left_homology_data.of_epi_of_is_iso_of_mono_π], }, }

end left_homology_map_data

instance (φ : S₁ ⟶ S₂) (h₁ : S₁.left_homology_data) (h₂ : S₂.left_homology_data)
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  is_iso (left_homology_map' φ h₁ h₂) :=
begin
  let h₂' := left_homology_data.of_epi_of_is_iso_of_mono φ h₁,
  haveI : is_iso (left_homology_map' φ h₁ h₂'),
  { let γ := left_homology_map_data.of_epi_of_is_iso_of_mono φ h₁,
    rw γ.left_homology_map'_eq,
    dsimp,
    apply_instance, },
  have eq := left_homology_map'_comp φ (𝟙 S₂) h₁ h₂' h₂,
  rw comp_id at eq,
  rw eq,
  apply_instance,
end

instance (φ : S₁ ⟶ S₂) [S₁.has_left_homology] [S₂.has_left_homology]
  [epi φ.τ₁] [is_iso φ.τ₂] [mono φ.τ₃] :
  is_iso (left_homology_map φ) :=
by { dsimp only [left_homology_map], apply_instance, }

end short_complex
