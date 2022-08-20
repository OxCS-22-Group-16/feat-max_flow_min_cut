import topology.sheaves.sheaf
import topology.sheaves.limits
import topology.sheaves.skyscraper
import topology.sheaves.stalks
import category_theory.preadditive.injective

noncomputable theory

section presheaf

open Top
open topological_space
open category_theory
open category_theory.limits

universes u v

variables {X : Top.{u}} {C : Type u} [category.{u} C]
variables [has_limits C] [has_terminal C] [has_colimits C]
variables [Π (x : X) (U : opens X), decidable (x ∈ U)]
variables (𝓕 : presheaf C X) (𝓖 : sheaf C X)

def godement_presheaf : presheaf C X :=
∏ (λ x, skyscraper_presheaf x (𝓕.stalk x) : X → presheaf C X)

@[simps] def godement_presheaf_obj (U : (opens X)ᵒᵖ) :
  (godement_presheaf 𝓕).obj U ≅ ∏ (λ x, (skyscraper_presheaf x (𝓕.stalk x)).obj U) :=
limit_obj_iso_limit_comp_evaluation _ _ ≪≫
{ hom := lim_map
  { app := λ _, 𝟙 _,
    naturality' := by { rintros ⟨x⟩ ⟨y⟩ ⟨⟨(rfl : x = y)⟩⟩, refl } },
  inv := lim_map
  { app := λ _, 𝟙 _,
    naturality' := by { rintros ⟨x⟩ ⟨y⟩ ⟨⟨(rfl : x = y)⟩⟩, refl } },
  hom_inv_id' :=
  begin
    dsimp,
    ext,
    erw [category.assoc, lim_map_π, ←category.assoc, lim_map_π, category.id_comp, category.comp_id,
      category.comp_id],
  end,
  inv_hom_id' :=
  begin
    dsimp,
    ext,
    erw [category.assoc, lim_map_π, ←category.assoc, lim_map_π, category.comp_id, category.id_comp,
      category.comp_id],
  end }

@[reducible]
def to_godement_presheaf_aux (U : (opens X)ᵒᵖ) :
  𝓕.obj U ⟶ ∏ λ (x : X), ite (x ∈ opposite.unop U) (𝓕.stalk x) (⊤_ C) :=
pi.lift (λ x, if m : x ∈ U.unop
  then 𝓕.germ ⟨x, m⟩ ≫ eq_to_hom ((skyscraper_presheaf_obj_of_mem _ m).symm.trans (by congr) :
    𝓕.stalk (⟨x, m⟩ : U.unop) = (skyscraper_presheaf x (𝓕.stalk x)).obj U)
  else terminal.from _ ≫ eq_to_hom (skyscraper_presheaf_obj_of_not_mem _ m).symm)

@[reducible]
def to_godement_presheaf_aux_comp_π {U : (opens X)ᵒᵖ} (p : U.unop) :
  𝓕.obj U ⟶ 𝓕.stalk p :=
to_godement_presheaf_aux 𝓕 U ≫ pi.π _ p ≫ eq_to_hom (if_pos p.2)

lemma to_godement_presheaf_aux_comp_π_eq {U : (opens X)ᵒᵖ} (p : U.unop) :
  to_godement_presheaf_aux_comp_π 𝓕 p = presheaf.germ 𝓕 p :=
begin
  dunfold to_godement_presheaf_aux_comp_π presheaf.germ to_godement_presheaf_aux,
  rw [←category.assoc, limit.lift_π],
  simp only [fan.mk_π_app],
  split_ifs,
  { rw [category.assoc, eq_to_hom_trans, eq_to_hom_refl, category.comp_id],
    refl },
  { exfalso, exact h p.2, },
end

@[simps] def to_godement_presheaf : 𝓕 ⟶ godement_presheaf 𝓕 :=
{ app := λ U, to_godement_presheaf_aux 𝓕 U ≫ (godement_presheaf_obj 𝓕 U).inv,
  naturality' :=
  begin
    intros U V inc,
    ext ⟨x⟩,
    dsimp,
    simp only [category.assoc, limit_obj_iso_limit_comp_evaluation_inv_π_app, lim_map_π,
      category.comp_id, nat_trans.naturality],
    simp only [←category.assoc _ _ ((skyscraper_presheaf _ _).map inc),
      limit_obj_iso_limit_comp_evaluation_inv_π_app, lim_map_π, category.comp_id],
    simp only [limit.lift_π, fan.mk_π_app, skyscraper_presheaf_map, category.id_comp,
      eq_to_hom_trans, comp_dite],
    dsimp,
    split_ifs with hV,
    { have hU : x ∈ U.unop := (le_of_hom inc.unop) hV,
      split_ifs,
      erw [category.assoc, eq_to_hom_trans, ←category.assoc, eq_comp_eq_to_hom,
        category.assoc, eq_to_hom_trans, eq_to_hom_refl, category.comp_id, 𝓕.germ_res inc.unop],
      refl },
    { rw [←category.assoc, eq_comp_eq_to_hom, category.assoc, category.assoc, eq_to_hom_trans,
        eq_to_hom_refl, category.comp_id],
      exact terminal_is_terminal.hom_ext _ _ },
  end }

lemma godement_presheaf_is_sheaf (h : 𝓕.is_sheaf) : (godement_presheaf 𝓕).is_sheaf :=
limit_is_sheaf _ $ λ ⟨x⟩, (skyscraper_sheaf x _).2

def godement_sheaf : sheaf C X :=
⟨godement_presheaf 𝓖.1, godement_presheaf_is_sheaf _ 𝓖.2⟩

def godement_sheaf_obj (U : (opens X)ᵒᵖ) :
  (godement_sheaf 𝓖).1.obj U ≅ ∏ (λ x, (skyscraper_presheaf x (𝓖.presheaf.stalk x)).obj U) :=
godement_presheaf_obj 𝓖.1 U

def to_godement_sheaf : 𝓖 ⟶ godement_sheaf 𝓖 :=
⟨to_godement_presheaf 𝓖.1⟩

variables [concrete_category.{u} C] [preserves_limits (forget C)]
variables [Π (U : opens X), preserves_colimits_of_shape
  ((opens.grothendieck_topology X).cover U)ᵒᵖ (forget C)]
variables [reflects_isomorphisms (forget C)] [preserves_filtered_colimits (forget C)]

@[simps] def sheaf_in_Type : sheaf C X ⥤ sheaf (Type u) X :=
{ obj := λ F, ⟨F.1 ⋙ forget C, (presheaf.is_sheaf_iff_is_sheaf_comp (forget C) F.1).mp F.2⟩,
  map := λ F G f, Sheaf.hom.mk
  { app := λ U, (forget C).map (f.1.app U),
    naturality' := λ U V inc, by erw [←(forget C).map_comp, ←(forget C).map_comp, f.1.naturality] },
  map_id' := λ F, by { ext, dsimp, rw [id_apply] },
  map_comp' := λ F G H f g, by { ext, dsimp, rw [comp_apply] } }

example : true := trivial


def godement_sheaf_in_Type : sheaf (Type u) X := sheaf_in_Type.obj (godement_sheaf 𝓖)

def godement_sheaf_in_Type_obj_aux (U : (opens X)ᵒᵖ) :
  (forget C).obj ∏ (λ x, (skyscraper_presheaf x (𝓖.presheaf.stalk x)).obj U) ≅
  ∏ (λ x, (forget C).obj ((skyscraper_presheaf x (𝓖.presheaf.stalk x)).obj U)) :=
{ hom := pi.lift $ λ p, (forget C).map $ pi.π _ p,
  inv :=
  begin
    refine lim_map _ ≫ (preserves_limit_iso (forget C) _).inv,
    refine { app := λ p x, x, naturality' := _ },
    rintros ⟨p⟩ ⟨q⟩ ⟨⟨(eq1 : p = q)⟩⟩,
    dsimp,
    induction eq1,
    ext1,
    dsimp,
    simp only [discrete.functor_map_id, types_id_apply, id_apply],
  end,
  hom_inv_id' :=
  begin
    rw [←category.assoc, limit.lift_map, iso.comp_inv_eq, category.id_comp],
    refine limit.hom_ext _,
    rintros ⟨p⟩,
    rw [preserves_limits_iso_hom_π, limit.lift_π],
    simpa only [cones.postcompose_obj_π, nat_trans.comp_app, fan.mk_π_app, forget_map_eq_coe],
  end,
  inv_hom_id' :=
  begin
    ext1 ⟨p⟩,
    rw [category.assoc, limit.lift_π, fan.mk_π_app, category.assoc, preserves_limits_iso_inv_π,
      lim_map_π, category.id_comp],
    refl,
  end }

def godement_sheaf_in_Type_obj (U : (opens X)ᵒᵖ) :
  (godement_sheaf_in_Type 𝓖).1.obj U ≅
  ∏ (λ x, (forget C).obj $ (skyscraper_presheaf x (𝓖.presheaf.stalk x)).obj U) :=
((forget C).map_iso $ godement_sheaf_obj 𝓖 U) ≪≫ godement_sheaf_in_Type_obj_aux 𝓖 U

def sheaf_in_Type_skyscraper_sheaf (x : X) (c : C) :
  (sheaf_in_Type.obj $ skyscraper_sheaf x c) ≅
  skyscraper_sheaf x ((forget C).obj c) :=
let e1 := preserves_limit_iso (forget C) (functor.empty.{0} C) in
have it : is_terminal $ (forget C).obj (terminal C),
from is_terminal.of_iso
begin
  rw show functor.empty C ⋙ forget C = functor.empty (Type u), from functor.empty_ext' _ _,
  exact terminal_is_terminal,
end e1.symm,
let e : (sheaf_in_Type.obj $ skyscraper_sheaf x c) ≅ skyscraper_sheaf' x ((forget C).obj c) it :=
{ hom := Sheaf.hom.mk
  { app := λ U, eq_to_hom
    begin
      change (forget C).obj _ = (skyscraper_sheaf' x ((forget C).obj c) _).1.obj _,
      by_cases hU : x ∈ U.unop,
      { erw [skyscraper_presheaf_obj_of_mem _ hU, skyscraper_sheaf'],
        dsimp, split_ifs, refl, },
      { erw [skyscraper_presheaf_obj_of_not_mem _ hU, skyscraper_sheaf'],
        dsimp, split_ifs, refl, },
    end,
    naturality' := λ U V inc,
    begin
      dsimp [skyscraper_sheaf', sheaf_in_Type, skyscraper_sheaf],
      change (forget C).map _ ≫ _ = _,
      by_cases hV : x ∈ V.unop,
      { have hU : x ∈ U.unop := le_of_hom inc.unop hV,
        split_ifs,
        simp only [category.id_comp, eq_to_hom_trans, eq_to_hom_refl, eq_to_hom_map],
        refl, },
      { split_ifs;
        symmetry;
        rw [←category.assoc, eq_comp_eq_to_hom];
        exact it.hom_ext _ _, },
    end },
  inv := Sheaf.hom.mk
  { app := λ U, eq_to_hom
    begin
      change (skyscraper_sheaf' x ((forget C).obj c) _).1.obj _ = (forget C).obj _,
      by_cases hU : x ∈ U.unop,
      { erw [skyscraper_presheaf_obj_of_mem _ hU, skyscraper_sheaf'],
        dsimp, split_ifs, refl, },
      { erw [skyscraper_presheaf_obj_of_not_mem _ hU, skyscraper_sheaf'],
        dsimp, split_ifs, refl, },
    end,
    naturality' := λ U V inc,
    begin
      dsimp [skyscraper_sheaf', sheaf_in_Type, skyscraper_sheaf],
      change _ = _ ≫ (forget C).map _,
      by_cases hV : x ∈ V.unop,
      { have hU : x ∈ U.unop := le_of_hom inc.unop hV,
        split_ifs,
        simp only [category.id_comp, eq_to_hom_trans, eq_to_hom_refl, eq_to_hom_map],
        refl, },
      { split_ifs;
        rw [eq_comp_eq_to_hom, eq_comp_eq_to_hom];
        exact it.hom_ext _ _, },
    end },
  hom_inv_id' :=
  begin
    ext : 3, dsimp,
    rw [eq_to_hom_trans, eq_to_hom_refl],
  end,
  inv_hom_id' :=
  begin
    ext : 3, dsimp,
    rw [eq_to_hom_trans, eq_to_hom_refl],
  end } in
e.trans $ (skyscraper_sheaf_iso _ _ it).symm

example : true := trivial

/--
`x y : 𝓖(U)`, and `p ∈ U`
``
-/
def stalk_bundles_eq0 (U : (opens X)ᵒᵖ) (x y : (sheaf_in_Type.obj 𝓖).1.obj U)
  (eq1 : (sheaf_in_Type.map (to_godement_sheaf 𝓖)).val.app U x =
      (sheaf_in_Type.map (to_godement_sheaf 𝓖)).val.app U y) (p : U.unop) :
  (forget C).map (to_godement_presheaf_aux 𝓖.presheaf U) x =
  (forget C).map (to_godement_presheaf_aux 𝓖.presheaf U) y :=
begin
  change (forget C).map ((to_godement_presheaf 𝓖.presheaf).app _) x =
    (forget C).map ((to_godement_presheaf 𝓖.presheaf).app _) y at eq1,
  dsimp at eq1,
  change (forget C).map _ x = (forget C).map _ y at eq1,
  have eq2 := congr_arg ((forget C).map (limit_obj_iso_limit_comp_evaluation (discrete.functor _) U).hom) eq1,
  dsimp at eq2,
  erw [←comp_apply, ←comp_apply, ←category.assoc] at eq2,
  simp only [category.assoc, iso.inv_hom_id, category.comp_id] at eq2,
  set α : nat_trans (discrete.functor (λ (x : ↥X), ite (x ∈ opposite.unop U) (𝓖.presheaf.stalk x) (⊤_ C)))
  (discrete.functor (λ (x : ↥X), skyscraper_presheaf x (𝓖.presheaf.stalk x)) ⋙
     (evaluation (opens ↥X)ᵒᵖ C).obj U) := _,
  change (forget C).map (_ ≫ lim_map α) x = (forget C).map (_ ≫ lim_map α) y at eq2,
  haveI : is_iso (lim_map α),
  { refine is_iso.mk ⟨lim_map { app := λ x, 𝟙 _, naturality' := _ }, _, _⟩,
    { rintros ⟨x⟩ ⟨y⟩ ⟨⟨eq0 : x = y⟩⟩, subst eq0, refl},
    { ext1, simp only [category.assoc, lim_map_π, category.comp_id, category.id_comp], },
    { ext1, simp only [category.assoc, lim_map_π, category.comp_id, category.id_comp], }, },
  have eq3 := congr_arg ((forget C).map (inv (lim_map α))) eq2,
  change ((forget C).map _ ≫ (forget C).map _) _ = ((forget C).map _ ≫ (forget C).map _) _ at eq3,
  simpa only [←(forget C).map_comp, category.assoc, is_iso.hom_inv_id,category.comp_id] using eq3,
end

def stalk_bundles_eq (U : (opens X)ᵒᵖ) (x y : (sheaf_in_Type.obj 𝓖).1.obj U)
  (eq1 : (sheaf_in_Type.map (to_godement_sheaf 𝓖)).val.app U x =
      (sheaf_in_Type.map (to_godement_sheaf 𝓖)).val.app U y) (p : U.unop) :
  (forget C).map (𝓖.presheaf.germ p) x = (forget C).map (𝓖.presheaf.germ p) y :=

begin
  have eq1' := stalk_bundles_eq0 𝓖 U x y eq1 p,
  have eq1'' : (forget C).map (to_godement_presheaf_aux_comp_π 𝓖.presheaf p) x =
    (forget C).map (to_godement_presheaf_aux_comp_π 𝓖.presheaf p) y,
  { dsimp at eq1' ⊢,
    dunfold to_godement_presheaf_aux_comp_π,
    simp only [comp_apply, eq1'], },
  rwa to_godement_presheaf_aux_comp_π_eq at eq1'',
end

example : true := trivial

def forget_stalk_iso (U : (opens X)ᵒᵖ) (x : U.unop) :
  (forget C).obj (𝓖.presheaf.stalk x) ≅ (sheaf_in_Type.obj 𝓖).presheaf.stalk x :=
preserves_colimit_iso _ _

lemma to_godement_sheaf_app_injective (U : opens X) :
  function.injective $ (forget C).map ((to_godement_sheaf 𝓖).1.app (opposite.op U)) :=
λ x y eq1, presheaf.section_ext _ _ _ _ (λ p, stalk_bundles_eq 𝓖 (opposite.op U) x y eq1 p)

instance : mono $ to_godement_sheaf 𝓖 :=
begin
  rw presheaf.mono_iff_stalk_mono,
  intros x,
  change mono ((presheaf.stalk_functor C x).map (to_godement_presheaf 𝓖.1)),
  rw concrete_category.mono_iff_injective_of_preserves_pullback,
  refine (presheaf.app_injective_iff_stalk_functor_map_injective (to_godement_presheaf 𝓖.1)).mpr
    (λ U x y eq1, presheaf.section_ext _ _ _ _ (λ p, stalk_bundles_eq 𝓖 (opposite.op U) x y eq1 p))
    x,
end

end presheaf
