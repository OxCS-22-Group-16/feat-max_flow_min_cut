import set_theory.ordinal_arithmetic

universes u v

namespace ordinal
section

/-- Bounded least upper bound. -/
noncomputable def blub (o : ordinal.{u}) (f : Π a < o, ordinal.{max u v}) : ordinal.{max u v} :=
bsup o (λ a ha, (f a ha).succ)

theorem blub_le_iff_lt {o f a} : blub.{u v} o f ≤ a ↔ ∀ i h, f i h < a :=
by { convert bsup_le, apply propext, simp [succ_le] }

theorem lt_blub {o} (f : Π a < o, ordinal) (i h) : f i h < blub o f :=
blub_le_iff_lt.1 (le_refl _) _ _

variables {S : set ordinal.{u}} (hS : ∀ α, ∃ β, S β ∧ α ≤ β)

/-- Enumerator function for an unbounded set of ordinals. For the subtype version, see `enum_ord`.
-/
noncomputable def enum_ord' : ordinal.{u} → ordinal.{u} :=
wf.fix (λ α f, omin _ (hS (blub.{u u} α f)))

/-- The equation that characterizes `enum_ord'` definitionally. This isn't the nicest expression to
work with, consider using `enum_ord'_def` instead. -/
theorem enum_ord'_def' (α) :
  enum_ord' hS α = omin (λ β, S β ∧ blub.{u u} α (λ γ _, enum_ord' hS γ) ≤ β) (hS _) :=
wf.fix_eq _ _

private theorem enum_ord'_mem_aux (α) :
  S (enum_ord' hS α) ∧ blub.{u u} α (λ γ _, enum_ord' hS γ) ≤ (enum_ord' hS α) :=
by { rw enum_ord'_def', exact omin_mem (λ _, _ ∧ _) _ }

theorem enum_ord'_mem (α) : enum_ord' hS α ∈ S := (enum_ord'_mem_aux hS α).left

theorem blub_le_enum_ord' (α) : blub.{u u} α (λ γ _, enum_ord' hS γ) ≤ enum_ord' hS α :=
(enum_ord'_mem_aux hS α).right

theorem enum_ord'.strict_mono {hS : ∀ α, ∃ β, S β ∧ α ≤ β} : strict_mono (enum_ord' hS) :=
λ _ _ h, lt_of_lt_of_le (lt_blub.{u u} _ _ h) (blub_le_enum_ord' hS _)

private theorem aux (α) : ∃ (β : ordinal), S β ∧ ∀ (γ : ordinal), γ < α → enum_ord' hS γ < β :=
by { refine ⟨enum_ord' hS α ,enum_ord'_mem hS α, λ _, _⟩, apply enum_ord'.strict_mono }

-- Explicitly specifying hS' screws up simp_rw for whatever reason.
private theorem enum_ord'_def_aux (α) {hS'} :
  enum_ord' hS α = omin (λ β, S β ∧ ∀ γ, γ < α → enum_ord' hS γ < β) (hS') :=
begin
  suffices : (λ β, S β ∧ blub.{u u} α (λ γ _, enum_ord' hS γ) ≤ β) =
    (λ β, S β ∧ ∀ γ, γ < α → enum_ord' hS γ < β),
  { rw enum_ord'_def',
    simp_rw this },
  apply funext (λ β, propext _),
  exact ⟨ λ ⟨hl, hr⟩, ⟨hl, λ _ h, lt_of_lt_of_le (lt_blub.{u u} _ _ h) hr⟩,
    λ ⟨hl, hr⟩, ⟨hl, blub_le_iff_lt.2 hr⟩ ⟩,
end

/-- A more workable definition for `enum_ord'`. -/
theorem enum_ord'_def (α) :
  enum_ord' hS α = omin (λ β, S β ∧ ∀ γ, γ < α → enum_ord' hS γ < β) (aux hS α) :=
enum_ord'_def_aux hS α

private theorem enum_ord'_lt_aux (α) :
  S (enum_ord' hS α) ∧ ∀ γ, γ < α → enum_ord' hS γ < (enum_ord' hS α) :=
by { rw enum_ord'_def, exact omin_mem (λ _, _ ∧ _) _ }

theorem enum_ord'_lt (α) : ∀ γ, γ < α → enum_ord' hS γ < enum_ord' hS α :=
(enum_ord'_lt_aux hS α).right

/-- Enumerator function for an unbounded set of ordinals. -/
noncomputable def enum_ord : ordinal.{u} → S := λ α, ⟨_, enum_ord'_mem hS α⟩

theorem enum_ord.strict_mono : strict_mono (enum_ord hS) :=
enum_ord'.strict_mono

theorem aux (α) : α ≤ enum_ord hS α :=
(enum_ord'.strict_mono).id_le_of_wo

theorem enum_ord.surjective : function.surjective (enum_ord hS) :=
begin
  intro α,
  have Swf : well_founded ((<) : S → S → Prop) := inv_image.wf _ wf,
  let γ : ordinal.{u} := omin (λ β, α ≤ enum_ord hS β) ⟨_, aux hS α⟩,
  use γ,
  have : enum_ord hS γ = α := sorry,
  exact H γ this,
end

end
end ordinal


/-- The subtype of fixed points of a function. -/
def fixed_points (f : ordinal.{u} → ordinal.{u}) : Type (u + 1) := {x // f x = x}

section
variable {f : ordinal.{u} → ordinal.{u}}

theorem le_of_strict_mono (hf : strict_mono f) : ∀ α, α ≤ f α :=
begin
  by_contra,
  push_neg at h,
  have h' := ordinal.omin_mem _ h,
  exact not_lt_of_ge (@ordinal.omin_le _ h (f _) (hf h')) h',
end

/-- An explicit fixed point for a normal function. Built as `sup {f^[n] α}`. -/
noncomputable def fixed_point (hf : ordinal.is_normal f) (α : ordinal.{u}) : fixed_points f :=
begin
  let g := λ n, f^[n] α,
  have H : ∀ {n}, g (n + 1) = (f ∘ g) n := λ n, function.iterate_succ_apply' f n α,
  have H' : ∀ {n}, g (n + 1) ≤ ordinal.sup.{0 u} (f ∘ g) := λ _, by {rw H, apply ordinal.le_sup},
  use ordinal.sup.{0 u} g,
  suffices : ordinal.sup.{0 u} (f ∘ g) = ordinal.sup.{0 u} g,
  { rwa @ordinal.is_normal.sup.{0 u u} f hf ℕ g (nonempty.intro 0) },
  apply has_le.le.antisymm;
  rw ordinal.sup_le;
  intro n,
  { rw ←H,
    exact ordinal.le_sup _ _ },
  cases n,
  { suffices : g 0 ≤ g 1,
    { exact le_trans this H' },
    change g 0 ≤ g 1 with (f^[0] α) ≤ (f^[1] α),
    rw [function.iterate_one f, function.iterate_zero_apply f α],
    exact le_of_strict_mono hf.strict_mono _ },
  exact H'
end

instance (hf : ordinal.is_normal f) : nonempty (fixed_points f) := ⟨fixed_point hf 0⟩

def fix_point_enum (hf : normal f) (α : ordinal.{u}) : fixed_points f := sorry
--ordinal.limit_rec_on α
