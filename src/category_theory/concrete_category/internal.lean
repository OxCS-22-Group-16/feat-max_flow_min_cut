import category_theory.concrete_category.operations
import category_theory.internal_operation

universes v₁ v₂ v₃ u₁ u₂ u₃

noncomputable theory

namespace category_theory

open category opposite limits

@[simp] lemma nat_trans.hcomp_id {C₁ C₂ C₃ : Type*} [category C₁] [category C₂] [category C₃]
  (F : C₁ ⥤ C₂) (G : C₂ ⥤ C₃) : (𝟙 F) ◫ (𝟙 G) = 𝟙 (F ⋙ G) := by tidy

namespace concrete_category

variables (A : Type u₂) [category.{v₂} A] [concrete_category.{v₁} A]
  (A' : Type u₃) [category.{v₃} A'] [concrete_category.{v₁} A']
  (C : Type u₁) [category.{v₁} C]

/-- The category of internal `A`-objects in the category `C`. -/
structure internal :=
(obj : C)
(presheaf : Cᵒᵖ ⥤ A)
(iso : yoneda.obj obj ≅ presheaf ⋙ forget A)

instance : category (internal A C) := induced_category.category (λ X, X.presheaf)

namespace internal

@[simps]
def presheaf_functor : internal A C ⥤ (Cᵒᵖ ⥤ A) := induced_functor _

@[simps]
def type_presheaf_functor : internal A C ⥤ (Cᵒᵖ ⥤ Type v₁) :=
presheaf_functor A C ⋙ (whiskering_right Cᵒᵖ A (Type v₁)).obj (forget A)

def obj_functor : internal A C ⥤ C :=
{ obj := λ X, X.obj,
  map := λ X Y f, yoneda.preimage ((X.iso.hom ≫ (f ◫ (𝟙 (forget A))) ≫ Y.iso.inv)),
  map_id' := λ X, yoneda.map_injective begin
    erw [functor.image_preimage, nat_trans.hcomp_id, id_comp, X.iso.hom_inv_id,
      yoneda.map_id],
  end,
  map_comp' := λ X Y Z f g, yoneda.map_injective begin
    simp only [functor.image_preimage, yoneda.map_comp, assoc, Y.iso.inv_hom_id_assoc],
    ext x : 2,
    simp only [nat_trans.comp_app, nat_trans.hcomp_id_app],
    erw [nat_trans.comp_app, functor.map_comp, assoc],
  end }

variables {A C} {Y Y' : C} (R : internal A C)

def presheaf_type := (type_presheaf_functor A C).obj R

lemma iso_hom_naturality (x : Y ⟶ R.obj) (f : Y' ⟶ Y) :
  R.iso.hom.app (op Y') (f ≫ x) = R.presheaf_type.map f.op (R.iso.hom.app (op Y) x) :=
congr_fun (R.iso.hom.naturality f.op) x

lemma iso_inv_naturality (x : R.presheaf_type.obj (op Y)) (f : Y' ⟶ Y) :
  R.iso.inv.app (op Y') (R.presheaf_type.map f.op x) = f ≫ R.iso.inv.app (op Y) x :=
congr_fun (R.iso.inv.naturality f.op) x

@[simp]
def hom.to_internal_yoneda_operation₁ {X₁ X₂ : internal A C} (f : X₁ ⟶ X₂) :
  internal_yoneda_operation₁_gen X₁.obj X₂.obj :=
  X₁.iso.hom ≫ (internal.type_presheaf_functor A C).map f ≫ X₂.iso.inv

@[simp]
lemma hom.to_internal_yoneda_operation₁_id (X : internal A C) :
  hom.to_internal_yoneda_operation₁ (𝟙 X) = 𝟙 _ :=
by { dsimp, erw [functor.map_id, id_comp, X.iso.hom_inv_id], }

@[simp]
lemma hom.to_internal_yoneda_operation₁_comp {X₁ X₂ X₃ : internal A C} (f : X₁ ⟶ X₂) (g : X₂ ⟶ X₃) :
  hom.to_internal_yoneda_operation₁ (f ≫ g) =
    hom.to_internal_yoneda_operation₁ f ≫ hom.to_internal_yoneda_operation₁ g :=
by { dsimp, simp only [functor.map_comp, assoc, X₂.iso.inv_hom_id_assoc], }

variables (A C)

@[protected]
def forget₂ [has_forget₂ A A'] : internal A C ⥤ internal A' C :=
{ obj := λ R,
  { obj := R.obj,
    presheaf := R.presheaf ⋙ forget₂ A A',
    iso := R.iso ≪≫ iso_whisker_left _ (eq_to_iso has_forget₂.forget_comp.symm) ≪≫
      (functor.associator _ _ _).symm, },
  map := λ R₁ R₂ f, whisker_right f (forget₂ A A'),
  map_id' := λ R, begin
    ext Y,
    dsimp,
    erw [nat_trans.id_app, nat_trans.id_app, functor.map_id],
    refl,
  end,
  map_comp' := λ R₁ R₂ R₃ f g, begin
    ext Y,
    dsimp [whisker_right],
    erw [nat_trans.comp_app, nat_trans.comp_app, functor.map_comp],
  end, }

example : ℕ := 43

variables {A C}

@[protected]
def Ab (R : internal A C) [has_forget₂ A Ab.{v₁}] : internal Ab.{v₁} C :=
(internal.forget₂ A Ab.{v₁} C).obj R

end internal

variables {A C}

open operations

namespace operation₀

variables (oper oper' : operation₀ A) (R : internal A C)

def on_internal_presheaf (Y : C) : R.presheaf_type.obj (op Y) :=
oper.app (R.presheaf.obj (op Y)) punit.star

lemma on_internal_presheaf_naturality {Y Y' : C} (f : Y' ⟶ Y) :
  oper.on_internal_presheaf R Y' = R.presheaf_type.map f.op (oper.on_internal_presheaf R Y) :=
congr_fun (oper.naturality (R.presheaf.map f.op)) punit.star

@[simp]
def to_internal_yoneda_operation₀_app (Y : C) : Y ⟶ R.obj :=
R.iso.inv.app (op Y) (oper.on_internal_presheaf R Y)

lemma to_internal_yoneda_operation₀_app_naturality {Y Y' : C} (f : Y' ⟶ Y) :
f ≫ oper.to_internal_yoneda_operation₀_app R Y = oper.to_internal_yoneda_operation₀_app R Y' :=
begin
  dsimp only [to_internal_yoneda_operation₀_app],
  rw [← R.iso_inv_naturality, oper.on_internal_presheaf_naturality R f],
end

@[simps]
def to_internal_yoneda_operation₀ : internal_yoneda_operation₀ R.obj :=
{ app := λ X s, oper.to_internal_yoneda_operation₀_app R X.unop,
  naturality' := λ X Y f, begin
    ext x,
    dsimp at x,
    have eq : x = punit.star := subsingleton.elim _ _,
    subst eq,
    exact (oper.to_internal_yoneda_operation₀_app_naturality R f.unop).symm,
  end }

end operation₀

namespace operation₁

variables (oper oper' : operation₁ A) {R : internal A C}

variables {Y Y' : C}

@[protected]
def on_internal_presheaf
  (x : R.presheaf_type.obj (op Y)) : R.presheaf_type.obj (op Y) :=
oper.app (R.presheaf.obj (op Y)) x

lemma on_internal_presheaf_naturality (x : R.presheaf_type.obj (op Y)) (f : Y' ⟶ Y) :
    oper.on_internal_presheaf (R.presheaf_type.map f.op x)  =
  R.presheaf_type.map f.op (oper.on_internal_presheaf x) :=
congr_fun (oper.naturality (R.presheaf.map f.op)) x

@[simp]
def to_internal_yoneda_operation₁_app (x : Y ⟶ R.obj) : Y ⟶ R.obj :=
R.iso.inv.app _ (oper.on_internal_presheaf (R.iso.hom.app (op Y) x))

lemma to_internal_yoneda_operation₁_app_naturality (x : Y ⟶ R.obj) (f : Y' ⟶ Y) :
  f ≫ oper.to_internal_yoneda_operation₁_app x = oper.to_internal_yoneda_operation₁_app (f ≫ x) :=
begin
  dsimp only [to_internal_yoneda_operation₁_app],
  simp only [R.iso_hom_naturality, on_internal_presheaf_naturality, R.iso_inv_naturality],
end

variable (R)

@[simps]
def to_internal_yoneda_operation₁ : internal_yoneda_operation₁ R.obj :=
{ app := λ X x, oper.to_internal_yoneda_operation₁_app x,
  naturality' := λ X Y f, begin
    ext x,
    symmetry,
    apply to_internal_yoneda_operation₁_app_naturality,
  end, }

end operation₁

namespace operation₂

variables (oper : operation₂ A) {R : internal A C}

variables {Y Y' : C}

@[protected]
def on_internal_presheaf
  (x y : R.presheaf_type.obj (op Y)) : R.presheaf_type.obj (op Y) :=
oper.app (R.presheaf.obj (op Y)) ⟨x,y⟩

lemma on_internal_presheaf_naturality (x y : R.presheaf_type.obj (op Y)) (f : Y' ⟶ Y) :
    oper.on_internal_presheaf (R.presheaf_type.map f.op x) (R.presheaf_type.map f.op y) =
  R.presheaf_type.map f.op (oper.on_internal_presheaf x y) :=
congr_fun (oper.naturality (R.presheaf.map f.op)) ⟨x,y⟩

@[simp]
def to_internal_yoneda_operation₂_app (x y : Y ⟶ R.obj) : Y ⟶ R.obj :=
R.iso.inv.app _ (oper.on_internal_presheaf (R.iso.hom.app (op Y) x) (R.iso.hom.app (op Y) y))

lemma to_internal_yoneda_operation₂_app_naturality (x y : Y ⟶ R.obj) (f : Y' ⟶ Y) :
  f ≫ oper.to_internal_yoneda_operation₂_app x y = oper.to_internal_yoneda_operation₂_app (f ≫ x) (f ≫ y) :=
begin
  dsimp only [to_internal_yoneda_operation₂_app],
  simp only [R.iso_hom_naturality, on_internal_presheaf_naturality, R.iso_inv_naturality],
end

variable (R)

@[simps]
def to_internal_yoneda_operation₂ :
  concat₂ (yoneda.obj R.obj) (yoneda.obj R.obj) ⟶ yoneda.obj R.obj :=
{ app := λ X x, oper.to_internal_yoneda_operation₂_app x.1 x.2,
  naturality' := λ X Y f, begin
    ext x,
    symmetry,
    apply to_internal_yoneda_operation₂_app_naturality,
  end, }

lemma to_internal_yoneda_operation₂_comm (oper_comm : oper.comm) :
  (oper.to_internal_yoneda_operation₂ R) =
    lift₂ pr₂ pr₁ ≫ (oper.to_internal_yoneda_operation₂ R) :=
begin
  dsimp at oper_comm,
  conv_lhs { rw oper_comm, },
  refl,
end

lemma to_internal_yoneda_operation₂_zero_add (zero : operation₀ A)
  (oper_zero : oper.zero_add zero) :
  lift₂ (to_functor_const_punit ≫ zero.to_internal_yoneda_operation₀ R) (𝟙 _) ≫
    oper.to_internal_yoneda_operation₂ R = 𝟙 _ :=
begin
  convert _root_.congr_arg (λ (m : operation₁ A), m.to_internal_yoneda_operation₁ R) oper_zero,
  { ext X x,
    dsimp at x ⊢,
    simp only [functor_to_types.inv_hom_id_app_apply],
    congr },
  { ext X x,
    dsimp [operation₁.on_internal_presheaf] at x ⊢,
    simp, },
end

lemma to_internal_yoneda_operation₂_add_left_neg (zero : operation₀ A) (neg : operation₁ A)
  (oper_left_neg : oper.add_left_neg zero neg) :
  lift₂ (neg.to_internal_yoneda_operation₁ R) (𝟙 _) ≫ oper.to_internal_yoneda_operation₂ R =
    to_functor_const_punit ≫ zero.to_internal_yoneda_operation₀ R :=
begin
  convert _root_.congr_arg (λ (m : operation₁ A), m.to_internal_yoneda_operation₁ R) oper_left_neg,
  ext X x,
  dsimp [operation₁.on_internal_presheaf, operation₀.on_internal_presheaf,
    operation₂.on_internal_presheaf],
  simp only [functor_to_types.inv_hom_id_app_apply],
end

end operation₂

namespace operation₃

variables (oper : operation₃ A) {R : internal A C} {Y Y' : C}

@[protected]
def on_internal_presheaf
  (x y z : R.presheaf_type.obj (op Y)) : R.presheaf_type.obj (op Y) :=
oper.app (R.presheaf.obj (op Y)) ⟨x, y, z⟩

lemma on_internal_presheaf_naturality (x y z : R.presheaf_type.obj (op Y)) (f : Y' ⟶ Y) :
    oper.on_internal_presheaf (R.presheaf_type.map f.op x) (R.presheaf_type.map f.op y)
      (R.presheaf_type.map f.op z) =
  R.presheaf_type.map f.op (oper.on_internal_presheaf x y z) :=
congr_fun (oper.naturality (R.presheaf.map f.op)) ⟨x, y, z⟩

@[simp]
def to_internal_yoneda_operation₃_app (x y z : Y ⟶ R.obj) : Y ⟶ R.obj :=
R.iso.inv.app _ (oper.on_internal_presheaf (R.iso.hom.app (op Y) x) (R.iso.hom.app (op Y) y)
  (R.iso.hom.app (op Y) z))

lemma to_internal_yoneda_operation₃_app_naturality (x y z : Y ⟶ R.obj) (f : Y' ⟶ Y) :
  f ≫ oper.to_internal_yoneda_operation₃_app x y z = oper.to_internal_yoneda_operation₃_app (f ≫ x) (f ≫ y) (f ≫ z) :=
begin
  dsimp only [to_internal_yoneda_operation₃_app],
  simp only [R.iso_hom_naturality, on_internal_presheaf_naturality, R.iso_inv_naturality],
end

variable (R)

@[simps]
def to_internal_yoneda_operation₃ :
  concat₃ (yoneda.obj R.obj) (yoneda.obj R.obj) (yoneda.obj R.obj) ⟶ yoneda.obj R.obj :=
{ app := λ X x, oper.to_internal_yoneda_operation₃_app x.1 x.2.1 x.2.2,
  naturality' := λ X Y f, begin
    ext x,
    symmetry,
    apply to_internal_yoneda_operation₃_app_naturality,
  end, }

end operation₃

namespace operation₂

variables (oper : operation₂ A) (R : internal A C)

lemma to_internal_yoneda_operation₂_assoc (oper_assoc : oper.assoc) :
  lift₂ (pr₁₂_₃ ≫ oper.to_internal_yoneda_operation₂ R) pr₃_₃ ≫ oper.to_internal_yoneda_operation₂ R =
    lift₂ pr₁_₃ (pr₂₃_₃ ≫ oper.to_internal_yoneda_operation₂ R) ≫ (oper.to_internal_yoneda_operation₂ R) :=
begin
  convert _root_.congr_arg (λ (m : operation₃ A), m.to_internal_yoneda_operation₃ R) oper_assoc;
  { ext X x,
    dsimp,
    simpa only [functor_to_types.inv_hom_id_app_apply], },
end

lemma to_internal_yoneda_operation₂_right_distrib (mul : operation₂ A) (add : operation₂ A)
  (R : internal A C) (h : mul.right_distrib add) :
  internal_yoneda_operation₂_gen.right_distrib (mul.to_internal_yoneda_operation₂ R)
    (add.to_internal_yoneda_operation₂ R) (add.to_internal_yoneda_operation₂ R) :=
begin
  have h' := _root_.congr_arg (λ (m : operation₃ A), m.to_internal_yoneda_operation₃ R) h,
  dsimp at h ⊢,
  convert h';
  { ext X x,
    dsimp,
    simpa, },
end

lemma to_internal_yoneda_operation₂_left_distrib (mul : operation₂ A) (add : operation₂ A)
  (R : internal A C) (h : mul.left_distrib add) :
  internal_yoneda_operation₂_gen.left_distrib (mul.to_internal_yoneda_operation₂ R)
    (add.to_internal_yoneda_operation₂ R) (add.to_internal_yoneda_operation₂ R) :=
begin
  have h' := _root_.congr_arg (λ (m : operation₃ A), m.to_internal_yoneda_operation₃ R) h,
  dsimp at h ⊢,
  convert h';
  { ext X x,
    dsimp,
    simpa, },
end

end operation₂

end concrete_category

open concrete_category concrete_category.operations

variables {A₁ A₂ A₃ A₄ C : Type*} [category A₁] [category A₂] [category A₃] [category A₄]
  [category.{v₁} C] [concrete_category.{v₁} A₁] [concrete_category.{v₁} A₂]
  [concrete_category.{v₁} A₃] [concrete_category.{v₁} A₄]
  {M₁ : internal A₁ C} {M₂ : internal A₂ C} {M₃ : internal A₃ C} {M₄ : internal A₄ C}

namespace internal_yoneda_operation₀

@[simp]
def to_presheaf (c : internal_yoneda_operation₀ M₁.obj) (Y : Cᵒᵖ) :=
  (c ≫ M₁.iso.hom).app Y punit.star

lemma to_presheaf_map (c : internal_yoneda_operation₀ M₁.obj) {Y Y' : Cᵒᵖ} (f : Y ⟶ Y') :
  (M₁.presheaf ⋙ forget A₁).map f (c.to_presheaf Y) = c.to_presheaf Y' :=
congr_fun ((c ≫ M₁.iso.hom).naturality f).symm punit.star

end internal_yoneda_operation₀

namespace internal_yoneda_operation₁_gen

variables (oper : internal_yoneda_operation₁_gen M₁.obj M₂.obj) {Y Y' : Cᵒᵖ}

@[simps]
def on_internal_presheaf : M₁.presheaf_type ⟶ M₂.presheaf_type :=
M₁.iso.inv ≫ oper ≫ M₂.iso.hom

end internal_yoneda_operation₁_gen

namespace internal_yoneda_operation₂_gen

variables (oper : internal_yoneda_operation₂_gen M₁.obj M₂.obj M₃.obj) {Y Y' : Cᵒᵖ}

def on_internal_presheaf : concat₂ M₁.presheaf_type M₂.presheaf_type ⟶ M₃.presheaf_type :=
lift₂ (pr₁ ≫ M₁.iso.inv) (pr₂ ≫ M₂.iso.inv) ≫ oper ≫ M₃.iso.hom

@[simp]
def on_internal_presheaf_curry
  (x₁ : M₁.presheaf_type.obj Y) (x₂ : M₂.presheaf_type.obj Y) :
  M₃.presheaf_type.obj Y :=
M₃.iso.hom.app _ (oper.app _ ⟨M₁.iso.inv.app _ x₁, M₂.iso.inv.app _ x₂⟩)

@[simp]
lemma on_internal_presheaf_app
  (x₁ : M₁.presheaf_type.obj Y) (x₂ : M₂.presheaf_type.obj Y) :
  oper.on_internal_presheaf.app Y ⟨x₁, x₂⟩ = oper.on_internal_presheaf_curry x₁ x₂ := rfl

def on_internal_presheaf_curry_naturality
  (f : Y ⟶ Y') (x₁ : M₁.presheaf_type.obj Y) (x₂ : M₂.presheaf_type.obj Y) :
  M₃.presheaf_type.map f (oper.on_internal_presheaf_curry x₁ x₂) =
  oper.on_internal_presheaf_curry (M₁.presheaf_type.map f x₁)
    (M₂.presheaf_type.map f x₂) :=
congr_fun (oper.on_internal_presheaf.naturality f).symm ⟨x₁, x₂⟩

end internal_yoneda_operation₂_gen

namespace internal_yoneda_operation₃_gen

variables (oper : internal_yoneda_operation₃_gen M₁.obj M₂.obj M₃.obj M₄.obj)

def on_internal_presheaf : concat₃ M₁.presheaf_type M₂.presheaf_type M₃.presheaf_type ⟶ M₄.presheaf_type :=
lift₃ (pr₁_₃ ≫ M₁.iso.inv) (pr₂_₃ ≫ M₂.iso.inv) (pr₃_₃ ≫ M₃.iso.inv) ≫ oper ≫ M₄.iso.hom

end internal_yoneda_operation₃_gen

end category_theory
