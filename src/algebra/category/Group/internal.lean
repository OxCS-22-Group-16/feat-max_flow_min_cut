import category_theory.concrete_category.internal
import algebra.category.Group.preadditive
import category_theory.internal_operation

noncomputable theory

def Ab.mk (A : Type*) (zero' : A) (neg' : A ⟶ A) (add' : A × A → A)
  (add_assoc' : ∀ (x y z : A), add' ⟨add' ⟨x, y⟩, z⟩ = add' ⟨x, add' ⟨y, z⟩⟩)
  (add_comm' : ∀ (x y : A), add' ⟨x, y⟩ = add' ⟨y, x⟩)
  (zero_add' : ∀ (x : A), add' ⟨zero', x⟩ = x)
  (add_left_neg' : ∀ (x : A), add' ⟨neg' x, x⟩ = zero') :
  Ab :=
⟨A,
{ zero := zero',
  neg := neg',
  add := λ x y, add' ⟨x, y⟩,
  add_assoc := add_assoc',
  add_comm := add_comm',
  zero_add := zero_add',
  add_zero := λ x, by { change add' ⟨x, zero'⟩ = x, rw [add_comm', zero_add'], },
  add_left_neg := add_left_neg', }⟩

namespace category_theory

open opposite limits

namespace concrete_category

namespace operations

def Ab_zero : operation₀ Ab :=
{ app := λ M, 0, }

def Ab_neg : operation₁ Ab :=
{ app := λ M x, -x, }

def Ab_add : operation₂ Ab :=
{ app := λ M x, x.1 + x.2, }

lemma Ab_add_comm : Ab_add.comm :=
by { ext M x, apply add_comm, }

lemma Ab_add_assoc : Ab_add.assoc :=
by { ext M x, apply add_assoc, }

lemma Ab_zero_add : Ab_add.add_zero Ab_zero :=
by { ext M x, apply zero_add, }

lemma Ab_add_left_neg : Ab_add.add_left_neg Ab_zero Ab_neg :=
by { ext M x, apply add_left_neg, }

end operations

namespace internal

namespace Ab

open concrete_category.operations limits

variables {C : Type*} [category C] (M : internal Ab C)

instance add_comm_group_presheaf_type_obj {Y : Cᵒᵖ} :
add_comm_group (M.presheaf_type.obj Y) :=
by { dsimp [presheaf_type], apply_instance, }

instance add_comm_group_presheaf_comp_forget_obj {Y : Cᵒᵖ} :
add_comm_group ((M.presheaf ⋙ forget Ab).obj Y) :=
by { dsimp [presheaf_type], apply_instance, }

def mk (X : C)
  (yoneda_zero : (functor.const Cᵒᵖ).obj punit ⟶ yoneda.obj X)
  (yoneda_neg : yoneda.obj X ⟶ yoneda.obj X)
  (yoneda_add : concat₂ (yoneda.obj X) (yoneda.obj X) ⟶ yoneda.obj X)
  (yoneda_add_comm : yoneda_add = lift₂ pr₂ pr₁ ≫ yoneda_add)
  (yoneda_add_assoc : lift₂ (pr₁₂_₃ ≫ yoneda_add) pr₃_₃ ≫ yoneda_add =
    lift₂ pr₁_₃ (pr₂₃_₃ ≫ yoneda_add) ≫ yoneda_add)
  (yoneda_zero_add : lift₂ (to_functor_const_punit ≫ yoneda_zero) (𝟙 _) ≫ yoneda_add = 𝟙 _ )
  (yoneda_add_left_neg : lift₂ yoneda_neg (𝟙 _) ≫ yoneda_add = to_functor_const_punit ≫ yoneda_zero) :
  internal Ab C :=
{ obj := X,
  presheaf :=
  { obj := λ Y, begin
      refine Ab.mk ((yoneda.obj X).obj Y) (yoneda_zero.app Y punit.star)
        (yoneda_neg.app Y) (yoneda_add.app Y) _ _ _ _,
      { intros x y z,
        exact congr_fun (congr_app yoneda_add_assoc Y) ⟨x, ⟨y, z⟩⟩, },
      { intros x y,
        exact congr_fun (congr_app yoneda_add_comm Y) ⟨x, y⟩, },
      { exact congr_fun (congr_app yoneda_zero_add Y), },
      { exact congr_fun (congr_app yoneda_add_left_neg Y), },
    end,
    map := λ Y Y' f, ⟨(yoneda.obj X).map f,
      congr_fun (yoneda_zero.naturality f).symm punit.star,
      λ x y, congr_fun (yoneda_add.naturality f).symm ⟨x, y⟩⟩, },
  iso := by refl, }

def mk' (X : C) [has_terminal C] [has_binary_product X X] [has_binary_product X (prod X X)]
  (zero : ⊤_ C ⟶ X) (neg : X ⟶ X) (add : prod X X ⟶ X) (add_comm : internal_operation₂.comm add)
  (add_assoc : internal_operation₂.assoc add) (add_zero : internal_operation₂.zero_add add zero)
  (add_left_neg : internal_operation₂.add_left_neg add zero neg) :
  internal Ab C :=
Ab.mk X (internal_operation₀.yoneda_equiv X zero)
  (internal_operation₁.yoneda_equiv X neg)
  (internal_operation₂.yoneda_equiv X add)
  (internal_operation₂.yoneda_equiv_comm X add add_comm)
  (internal_operation₂.yoneda_equiv_assoc X add add_assoc)
  (internal_operation₂.yoneda_equiv_zero_add X add zero add_zero)
  (internal_operation₂.yoneda_equiv_add_left_neg X add zero neg add_left_neg)

def yoneda_operation_zero := Ab_zero.to_internal_yoneda_operation₀ M
def yoneda_operation_neg := Ab_neg.to_internal_yoneda_operation₁ M
def yoneda_operation_add := Ab_add.to_internal_yoneda_operation₂ M
def zero [has_terminal C] := (internal_operation₀.yoneda_equiv _).symm (yoneda_operation_zero M)
def neg := (internal_operation₁.yoneda_equiv _).symm (yoneda_operation_neg M)
def add [has_binary_product M.obj M.obj]:= (internal_operation₂.yoneda_equiv _).symm (yoneda_operation_add M)

lemma yoneda_operation_add_comm : yoneda_operation_add M = lift₂ pr₂ pr₁ ≫ yoneda_operation_add M :=
Ab_add.to_internal_yoneda_operation₂_comm M Ab_add_comm

lemma yoneda_operation_add_assoc :
  lift₂ (pr₁₂_₃ ≫ yoneda_operation_add M) pr₃_₃ ≫ yoneda_operation_add M =
    lift₂ pr₁_₃ (pr₂₃_₃ ≫ yoneda_operation_add M) ≫ yoneda_operation_add M :=
Ab_add.to_internal_yoneda_operation₂_assoc M Ab_add_assoc

lemma yoneda_operation_zero_add :
  lift₂ (to_functor_const_punit ≫ yoneda_operation_zero M) (𝟙 _) ≫
    yoneda_operation_add M = 𝟙 _  :=
Ab_add.to_internal_yoneda_operation₂_add_zero M Ab_zero Ab_zero_add

lemma yoneda_operation_add_left_neg :
lift₂ (yoneda_operation_neg M) (𝟙 _) ≫ yoneda_operation_add M =
  to_functor_const_punit ≫ yoneda_operation_zero M :=
Ab_add.to_internal_yoneda_operation₂_add_left_neg M Ab_zero Ab_neg Ab_add_left_neg

lemma add_comm [has_binary_product M.obj M.obj] : (add M).comm :=
internal_operation₂.yoneda_equiv_symm_comm M.obj _ (yoneda_operation_add_comm M)

lemma add_assoc [has_binary_product M.obj M.obj] [has_binary_product M.obj (prod M.obj M.obj)] :
  (add M).assoc :=
internal_operation₂.yoneda_equiv_symm_assoc M.obj _ (yoneda_operation_add_assoc M)

variable {M}

@[simp]
lemma iso_hom_app_yoneda_operation_add_app {Y : C} (x₁ x₂ : Y ⟶ M.obj) :
  M.iso.hom.app _ ((yoneda_operation_add M).app (op Y) ⟨x₁, x₂⟩) =
  M.iso.hom.app (op Y) x₁ + M.iso.hom.app (op Y) x₂ :=
begin
  dsimp [yoneda_operation_add],
  simpa only [functor_to_types.inv_hom_id_app_apply],
end

variables (M₁ M₂ M₃ : internal Ab C)

structure yoneda_bilinear :=
(φ : internal_yoneda_operation₂_gen M₁.obj M₂.obj M₃.obj)
(right_distrib : internal_yoneda_operation₂_gen.right_distrib φ (Ab.yoneda_operation_add _)
    (Ab.yoneda_operation_add _))
(left_distrib : internal_yoneda_operation₂_gen.left_distrib φ (Ab.yoneda_operation_add _)
    (Ab.yoneda_operation_add _))

namespace yoneda_bilinear

variables (bil : yoneda_bilinear M₁ M₂ M₃) {M₁ M₂ M₃} {Y Y' : C}

def on_internal_presheaf : concat₂ M₁.presheaf_type M₂.presheaf_type ⟶ M₃.presheaf_type :=
lift₂ (pr₁ ≫ M₁.iso.inv) (pr₂ ≫ M₂.iso.inv) ≫ bil.φ ≫ M₃.iso.hom

@[simp]
def on_internal_presheaf_curry
  (x₁ : M₁.presheaf_type.obj (op Y)) (x₂ : M₂.presheaf_type.obj (op Y)) :
  M₃.presheaf_type.obj (op Y) :=
M₃.iso.hom.app _ (bil.φ.app _ ⟨M₁.iso.inv.app _ x₁, M₂.iso.inv.app _ x₂⟩)

@[simp]
lemma on_internal_presheaf_app
  (x₁ : M₁.presheaf_type.obj (op Y)) (x₂ : M₂.presheaf_type.obj (op Y)) :
  bil.on_internal_presheaf.app (op Y) ⟨x₁, x₂⟩ = bil.on_internal_presheaf_curry x₁ x₂ := rfl

def on_internal_presheaf_curry_naturality
  (x₁ : M₁.presheaf_type.obj (op Y)) (x₂ : M₂.presheaf_type.obj (op Y)) (f : Y' ⟶ Y) :
  bil.on_internal_presheaf_curry (M₁.presheaf_type.map f.op x₁)
    (M₂.presheaf_type.map f.op x₂) =
  M₃.presheaf_type.map f.op (bil.on_internal_presheaf_curry x₁ x₂) :=
congr_fun (bil.on_internal_presheaf.naturality f.op) ⟨x₁, x₂⟩

lemma on_internal_presheaf_right_distrib
  (x₁ x₁' : M₁.presheaf_type.obj (op Y)) (x₂ : M₂.presheaf_type.obj (op Y)) :
bil.on_internal_presheaf_curry (x₁ + x₁') x₂ =
  bil.on_internal_presheaf_curry x₁ x₂ + bil.on_internal_presheaf_curry x₁' x₂ :=
begin
  have h := congr_fun (nat_trans.congr_app bil.right_distrib (op Y))
    ⟨M₁.iso.inv.app _ x₁, M₁.iso.inv.app _ x₁', M₂.iso.inv.app _ x₂⟩,
  have h₂ := congr_arg (M₃.iso.hom.app _) h,
  simp only [functor_to_types.comp, lift₂_app, pr₁₂_₃_app, pr₃_₃_app, has_coe_to_fun_Type,
    pr₁₃_₃_app, pr₂₃_₃_app, iso_hom_app_yoneda_operation_add_app] at h₂,
  convert h₂;
  { dsimp, simp only [functor_to_types.inv_hom_id_app_apply], },
end

end yoneda_bilinear

end Ab

end internal

end concrete_category

end category_theory
