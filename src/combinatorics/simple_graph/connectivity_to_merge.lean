/-
Copyright (c) 2021 Kyle Miller. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kyle Miller
-/
import combinatorics.simple_graph.connectivity
/-!

# Graph connectivity

## Main definitions

* `simple_graph.is_acyclic` and `simple_graph.is_tree`

* `simple_graph.edge_connected` for k-edge-connectivity of a graph

## Tags
walks, trails, paths, circuits, cycles

-/

/-- this doesn't seem to be used in this file anymore (was a simp lemma) -/
lemma function.injective.mem_list_map_iff {α β : Type*} {f : α → β} {l : list α} {a : α}
  (hf : function.injective f) :
  (∃ (a' : α), a' ∈ l ∧ f a' = f a) ↔ a ∈ l :=
begin
  split,
  { rintro ⟨a', ha', h⟩,
    cases hf h,
    assumption },
  { intro h,
    exact ⟨_, h, rfl⟩ },
end

universes u

open function

namespace simple_graph
variables {V : Type u} {V' : Type*} (G : simple_graph V)

/-! ### Walks to paths -/


namespace walk
variables {G} [decidable_eq V]

/-- Whether or not the path `p` is a prefix of the path `q`. -/
def prefix_of : Π {u v w : V} (p : G.walk u v) (q : G.walk u w), Prop
| u v w nil _ := true
| u v w (cons _ _) nil := false
| u v w (cons' _ x _ r p) (@cons _ _ _ y _ s q) :=
  if h : x = y
  then by { subst y, exact prefix_of p q }
  else false

end walk


namespace path
variables {G} {G' : simple_graph V'}

lemma singleton_edge_mem {u v : V} (h : G.adj u v) : ⟦(u, v)⟧ ∈ (singleton h : G.walk u v).edges :=
by simp [singleton]

lemma support_count_eq_one [decidable_eq V] {u v w : V} {p : G.path u v}
  (hw : w ∈ (p : G.walk u v).support) : (p : G.walk u v).support.count w = 1 :=
list.count_eq_one_of_mem p.property.support_nodup hw

lemma edges_count_eq_one [decidable_eq V] {u v : V} {p : G.path u v} (e : sym2 V)
  (hw : e ∈ (p : G.walk u v).edges) : (p : G.walk u v).edges.count e = 1 :=
list.count_eq_one_of_mem p.property.to_trail.edges_nodup hw

lemma nonempty_path_not_loop {v : V} {e : sym2 V} (p : G.path v v)
  (h : e ∈ walk.edges (p : G.walk v v)) : false :=
begin
  cases p with p hp,
  cases p,
  { exact h },
  { cases hp,
    simpa using hp_support_nodup },
end

end path

/-! ## `reachable` and `connected` -/


variables (G)

/-- A graph is *k-edge-connected* if it remains connected whenever
fewer than k edges are removed. -/
def edge_connected (k : ℕ) : Prop :=
∀ (s : finset (sym2 V)), ↑s ⊆ G.edge_set → s.card < k → (G.delete_edges ↑s).connected

variables {G}

lemma edge_connected.to_preconnected {k : ℕ} (h : G.edge_connected k) (hk : 0 < k) :
  G.preconnected :=
begin
  intros v w,
  simpa using (h ∅ (by simp) (by simp [hk])).preconnected v w,
end

lemma edge_connected.to_connected {k : ℕ} (h : G.edge_connected k) (hk : 0 < k) : G.connected :=
let C' := h ∅ (by simp) (by simp [hk]) in
{ preconnected := by simpa using C'.preconnected,
  nonempty := C'.nonempty }

variables (G)

/-- A graph is *acyclic* (or a *forest*) if it has no cycles.

A characterization: `simple_graph.is_acyclic_iff`.-/
def is_acyclic : Prop := ∀ (v : V) (c : G.walk v v), ¬c.is_cycle

/-- A *tree* is a connected acyclic graph. -/
def is_tree : Prop := G.connected ∧ G.is_acyclic

namespace subgraph
variables {G} (H : subgraph G)

/-- An edge of a subgraph is a bridge edge if, after removing it, its incident vertices
are no longer reachable.  The vertices are meant to be adjacent.

Since this is for simple graphs, we use the endpoints of the vertices as the edge itself.

Implementation note: this uses `simple_graph.subgraph.spanning_coe` since adding
vertices to a subgraph does not change reachability, and it is simpler than
dealing with the dependent types from `simple_graph.subgraph.coe`. -/
def is_bridge (v w : V) : Prop :=
¬(H.delete_edges {⟦(v, w)⟧}).spanning_coe.reachable v w

end subgraph

/-- An edge of a graph is a bridge if, after removing it, its incident vertices
are no longer reachable.

Characterizations of bridges:
`simple_graph.is_bridge_iff_walks_contain`
`is_bridge_iff_no_cycle_contains` -/
def is_bridge (v w : V) : Prop := ¬ (G.delete_edges {⟦(v, w)⟧}).reachable v w

lemma is_bridge_iff_forall_walk_mem_edges {v w : V} :
  G.is_bridge v w ↔ ∀ (p : G.walk v w), ⟦(v, w)⟧ ∈ p.edges :=
begin
  refine ⟨λ hb p, _, _⟩,
  { by_contra he,
    exact hb ⟨p.to_delete_edge _ he⟩ },
  { rintro hpe ⟨p'⟩,
    specialize hpe (p'.map (hom.map_spanning_subgraphs (G.delete_edges_le _))),
    simp only [set_coe.exists, walk.edges_map, list.mem_map] at hpe,
    obtain ⟨z, he, hd⟩ := hpe,
    simp only [hom.map_spanning_subgraphs, rel_hom.coe_fn_mk, sym2.map_id', id.def] at hd,
    simpa [hd] using p'.edges_subset_edge_set he }
end



lemma is_bridge_iff_no_cycle_contains.aux1 [decidable_eq V]
  {u v w : V}
  (hb : ∀ (p : G.walk v w), ⟦(v, w)⟧ ∈ p.edges)
  (c : G.walk u u)
  (hc : c.is_trail)
  (he : ⟦(v, w)⟧ ∈ c.edges)
  (hw : w ∈ (c.take_until v (c.fst_mem_support_of_mem_edges he)).support) :
  false :=
begin
  have hv := c.fst_mem_support_of_mem_edges he,
  -- decompose c into
  --      puw     pwv     pvu
  --   u ----> w ----> v ----> u
  let puw := (c.take_until v hv).take_until w hw,
  let pwv := (c.take_until v hv).drop_until w hw,
  let pvu := c.drop_until v hv,
  have : c = (puw.append pwv).append pvu := by simp,
  -- We have two walks from v to w
  --      pvu     puw
  --   v ----> u ----> w
  --   |               ^
  --    `-------------'
  --      pwv.reverse
  -- so they both contain the edge ⟦(v, w)⟧, but that's a contradiction since c is a trail.
  have hbq := hb (pvu.append puw),
  have hpq' := hb pwv.reverse,
  rw [walk.edges_reverse, list.mem_reverse] at hpq',
  rw [walk.is_trail_def, this, walk.edges_append, walk.edges_append,
      list.nodup_append_comm, ← list.append_assoc, ← walk.edges_append] at hc,
  exact list.disjoint_of_nodup_append hc hbq hpq',
end

lemma is_bridge_iff_no_cycle_contains {v w : V} (h : G.adj v w) :
  G.is_bridge v w ↔ ∀ {u : V} (p : G.walk u u), p.is_cycle → ⟦(v, w)⟧ ∉ p.edges :=
begin
  classical,
  split,
  { intros hb u c hc he,
    rw is_bridge_iff_forall_walk_mem_edges at hb,
    have hvc : v ∈ c.support := walk.fst_mem_support_of_mem_edges c he,
    have hwc : w ∈ c.support := walk.snd_mem_support_of_mem_edges c he,
    let puv := c.take_until v hvc,
    let pvu := c.drop_until v hvc,
    obtain (hw | hw') : w ∈ puv.support ∨ w ∈ pvu.support,
    { rwa [← walk.mem_support_append_iff, walk.take_spec] },
    { exact is_bridge_iff_no_cycle_contains.aux1 G hb c hc.to_trail he hw },
    { have hb' : ∀ (p : G.walk w v), ⟦(w, v)⟧ ∈ p.edges,
      { intro p,
        simpa [sym2.eq_swap] using hb p.reverse, },
      apply is_bridge_iff_no_cycle_contains.aux1 G hb' (pvu.append puv)
        (hc.to_trail.rotate hvc) _ (walk.start_mem_support _),
      rwa [walk.edges_append, list.mem_append, or_comm, ← list.mem_append,
           ← walk.edges_append, walk.take_spec, sym2.eq_swap], } },
  { rw is_bridge_iff_forall_walk_mem_edges,
    intros hc p,
    by_contra hne,
    apply hc (walk.cons h.symm p.to_path),
    { apply path.cons_is_cycle,
      rw sym2.eq_swap,
      intro h,
      exact absurd (walk.edges_to_path_subset p h) hne, },
    simp only [sym2.eq_swap, walk.edges_cons, list.mem_cons_iff, eq_self_iff_true, true_or], },
end

lemma is_acyclic_iff_all_bridges : G.is_acyclic ↔ ∀ {v w : V}, G.adj v w → G.is_bridge v w :=
begin
  split,
  { intros ha v w hvw,
    rw is_bridge_iff_no_cycle_contains _ hvw,
    intros u p hp,
    exact absurd hp (ha _ p), },
  { rintros hb v (_ | @⟨_, _, _, ha, p⟩) hp,
    { exact hp.not_of_nil },
    { specialize hb ha,
      rw is_bridge_iff_no_cycle_contains _ ha at hb,
      apply hb _ hp,
      rw [walk.edges_cons],
      apply list.mem_cons_self } },
end

lemma unique_path_of_is_acyclic (h : G.is_acyclic) {v w : V} (p q : G.path v w) : p = q :=
begin
  obtain ⟨p, hp⟩ := p,
  obtain ⟨q, hq⟩ := q,
  simp only,
  induction p with u pu pv pw ph p ih generalizing q,
  { cases q,
    { refl },
    { simpa [walk.is_path_def] using hq, } },
  { rw is_acyclic_iff_all_bridges at h,
    specialize h ph,
    rw is_bridge_iff_forall_walk_mem_edges at h,
    specialize h (q.append p.reverse),
    simp only [walk.edges_append, walk.edges_reverse, list.mem_append, list.mem_reverse] at h,
    cases h,
    { cases q,
      { simpa [walk.is_path_def] using hp },
      { rw walk.cons_is_path_iff at hp hq,
        simp only [walk.edges_cons, list.mem_cons_iff, sym2.eq_iff] at h,
        obtain (⟨h,rfl⟩ | ⟨rfl,rfl⟩) | h := h,
        { rw [ih hp.1 _ hq.1] },
        { simpa using hq },
        { exact absurd (walk.fst_mem_support_of_mem_edges _ h) hq.2 } } },
    { rw walk.cons_is_path_iff at hp,
      exact absurd (walk.fst_mem_support_of_mem_edges _ h) hp.2 } }
end

lemma is_acyclic_of_unique_path (h : ∀ (v w : V) (p q : G.path v w), p = q) : G.is_acyclic :=
begin
  intros v c hc,
  simp only [walk.is_cycle_def, ne.def] at hc,
  cases c,
  { exact absurd rfl hc.2.1 },
  { simp only [walk.cons_is_trail_iff, not_false_iff, walk.support_cons,
      list.tail_cons, true_and] at hc,
    specialize h _ _ ⟨c_p, by simp only [walk.is_path_def, hc.2]⟩ (path.singleton (G.symm c_h)),
    simp only [path.singleton] at h,
    simpa [-quotient.eq, sym2.eq_swap, h] using hc },
end

lemma is_acyclic_iff : G.is_acyclic ↔ ∀ (v w : V) (p q : G.path v w), p = q :=
⟨unique_path_of_is_acyclic _, is_acyclic_of_unique_path _⟩

lemma is_tree_iff : G.is_tree ↔ nonempty V ∧ ∀ (v w : V), ∃!(p : G.walk v w), p.is_path :=
begin
  classical,
  simp only [is_tree, is_acyclic_iff],
  split,
  { rintro ⟨hc, hu⟩,
    refine ⟨hc.nonempty, _⟩,
    intros v w,
    let q := (hc.1 v w).some.to_path,
    use q,
    simp only [true_and, path.is_path],
    intros p hp,
    specialize hu v w ⟨p, hp⟩ q,
    simp only [←hu, subtype.coe_mk], },
  { rintro ⟨hV, h⟩,
    refine ⟨@connected.mk V _ _ hV, _⟩,
    { intros v w,
      obtain ⟨p, hp⟩ := h v w,
      use p, },
    { rintros v w ⟨p, hp⟩ ⟨q, hq⟩,
      simp only [unique_of_exists_unique (h v w) hp hq] } },
end

/-- Get the unique path between two vertices in the tree. -/
noncomputable abbreviation tree_path (h : G.is_tree) (v w : V) : G.path v w :=
⟨((G.is_tree_iff.mp h).2 v w).some, ((G.is_tree_iff.mp h).2 v w).some_spec.1⟩

lemma tree_path_spec {h : G.is_tree} {v w : V} (p : G.path v w) : p = G.tree_path h v w :=
begin
  cases p,
  have := ((G.is_tree_iff.mp h).2 v w).some_spec,
  simp only [this.2 p_val p_property],
end

/-- The tree metric, which is the length of the path between any two vertices.

Fixing a vertex as the root, then `G.tree_dist h root` gives the depth of each node with
respect to the root. -/
noncomputable def tree_dist (h : G.is_tree) (v w : V) : ℕ :=
walk.length (G.tree_path h v w : G.walk v w)

variables {G}

/-- Given a tree and a choice of root, then we can tell whether a given ordered
pair of adjacent vertices `v` and `w` is *rootward* based on whether or not `w` lies
on the path from `v` to the root.

This gives paths a canonical orientation in a rooted tree. -/
def is_rootward (h : G.is_tree) (root : V) (v w : V) : Prop :=
G.adj v w ∧ ⟦(v, w)⟧ ∈ (G.tree_path h v root : G.walk v root).edges

lemma is_rootward_antisymm (h : G.is_tree) (root : V) : anti_symmetric (is_rootward h root) :=
begin
  classical,
  rintros v w ⟨ha, hvw⟩ ⟨ha', hwv⟩,
  by_contra hne,
  rw sym2.eq_swap at hwv,
  have hv := walk.fst_mem_support_of_mem_edges _ hwv,
  have h' := h.2,
  rw is_acyclic_iff at h',
  specialize h' _ _
    (G.tree_path h v root)
    ⟨walk.drop_until _ _ hv, walk.is_path.drop_until _ (path.is_path _) _⟩,
  have hs := congr_arg (λ p, multiset.count w ↑(walk.support p)) (walk.take_spec _ hv),
  dsimp only at hs,
  rw h' at hvw,
  have hw := walk.fst_mem_support_of_mem_edges _ hwv,
  rw walk.coe_support_append' at hs,
  have : multiset.count w {v} = 0,
  { simp only [multiset.cons_zero, multiset.count_eq_zero, multiset.mem_singleton],
    simpa using ne.symm hne },
  rw [multiset.count_sub, this, tsub_zero, multiset.count_add] at hs,
  simp_rw [multiset.coe_count] at hs,
  rw [path.support_count_eq_one] at hs,
  swap, { simp },
  rw ←subtype.coe_mk (walk.take_until _ _ _) at hs,
  swap, { apply walk.is_path.take_until, apply path.is_path },
  rw ←subtype.coe_mk (walk.drop_until _ _ _) at hs,
  swap, { apply walk.is_path.drop_until, apply path.is_path },
  rw [path.support_count_eq_one, path.support_count_eq_one] at hs,
  simpa using hs,
  apply walk.fst_mem_support_of_mem_edges _ (by { rw [sym2.eq_swap], exact hvw }),
  apply walk.start_mem_support,
end

lemma is_rootward_or_reverse (h : G.is_tree) (root : V) {v w : V} (hvw : G.adj v w) :
  is_rootward h root v w ∨ is_rootward h root w v :=
begin
  classical,
  have h' := h.2,
  rw is_acyclic_iff at h',
  by_contra hr,
  simp only [is_rootward] at hr,
  push_neg at hr,
  rcases hr with ⟨hrv, hrw⟩,
  specialize hrv hvw,
  specialize hrw (G.symm hvw),
  let p := (G.tree_path h v root : G.walk v root).append
           (G.tree_path h w root : G.walk w root).reverse,
  specialize h' _ _ (path.singleton hvw) p.to_path,
  have hp := walk.edges_to_path_subset p,
  rw [←h', walk.edges_append, walk.edges_reverse] at hp,
  specialize hp (path.singleton_edge_mem hvw),
  rw [list.mem_append, list.mem_reverse] at hp,
  rw sym2.eq_swap at hrw,
  cases hp; simpa only [hrv, hrw] using hp,
end

open fintype

/-- Get the next edge after vertext `v` on a path `p` from `v` to vertex `w`. -/
def next_edge (G : simple_graph V) : ∀ (v w : V) (h : v ≠ w) (p : G.walk v w), G.incidence_set v
| v w h walk.nil := (h rfl).elim
| v w h (@walk.cons _ _ _ u _ hvw _) := ⟨⟦(v, u)⟧, hvw, sym2.mem_mk_left _ _⟩

lemma eq_next_edge_if_mem_path {u v w : V}
  (hne : u ≠ v) (hinc : ⟦(u, w)⟧ ∈ G.incidence_set u)
  (p : G.path u v) (h : ⟦(u, w)⟧ ∈ (p : G.walk u v).edges) :
  G.next_edge u v hne p = ⟨⟦(u, w)⟧, hinc⟩ :=
begin
  cases p with p hp,
  cases p,
  { exact (hne rfl).elim },
  { cases hp,
    simp at hp_support_nodup,
    simp only [next_edge, subtype.mk_eq_mk, subtype.coe_mk],
    congr,
    simp only [list.mem_cons_iff, subtype.coe_mk, simple_graph.walk.edges_cons, sym2.eq_iff] at h,
    cases h,
    { obtain (⟨_,rfl⟩|⟨rfl,rfl⟩) := h; refl },
    { have h := walk.fst_mem_support_of_mem_edges _ h,
      exact (hp_support_nodup.1 h).elim } },
end

lemma next_edge_mem_edges (G : simple_graph V) (v w : V) (h : v ≠ w) (p : G.walk v w) :
  (G.next_edge v w h p : sym2 V) ∈ p.edges :=
begin
  cases p with p hp,
  { exact (h rfl).elim },
  { simp only [next_edge, list.mem_cons_iff, walk.edges_cons, subtype.coe_mk],
    left,
    refl,},
end

lemma is_tree.card_edges_eq_card_vertices_sub_one
  [fintype G.edge_set] [fintype V] [nonempty V] (h : G.is_tree) :
  card G.edge_set = card V - 1 :=
begin
  classical,
  have root := classical.arbitrary V,
  rw ←set.card_ne_eq root,
  let f : {v | v ≠ root} → G.edge_set := λ v,
    ⟨G.next_edge v root v.property (G.tree_path h v root),
     G.incidence_set_subset _ (subtype.mem _)⟩,
  have finj : function.injective f,
  { rintros ⟨u₁, h₁⟩ ⟨u₂, h₂⟩,
    by_cases hne : u₁ = u₂,
    { simp [hne] },
    simp only [subtype.mk_eq_mk, subtype.coe_mk],
    generalize he₁ : G.next_edge _ _ _ _ = e₁,
    generalize he₂ : G.next_edge _ _ _ _ = e₂,
    cases e₁ with e₁ heu₁,
    cases e₂ with e₂ heu₂,
    simp only [subtype.coe_mk],
    rintro rfl,
    cases heu₁ with heu₁_edge heu₁_adj,
    cases heu₂ with heu₂_edge heu₂_adj,
    simp only [subtype.coe_mk] at heu₁_adj heu₂_adj,
    have e_is : e₁ = ⟦(u₁, u₂)⟧,
    { induction e₁ using sym2.ind with v₁ w₁,
      simp only [sym2.mem_iff] at heu₁_adj heu₂_adj,
      obtain (rfl|rfl) := heu₁_adj;
      obtain (rfl|rfl) := heu₂_adj;
      try { exact (hne rfl).elim };
      simp [sym2.eq_swap] },
    subst e₁,
    apply is_rootward_antisymm h root,
    { split,
      { exact heu₂_edge, },
      { convert G.next_edge_mem_edges _ _ h₁ _,
        erw he₁,
        refl } },
    { split,
      { exact G.symm heu₂_edge, },
      { convert G.next_edge_mem_edges _ _ h₂ _,
        erw he₂, simp [sym2.eq_swap] } } },
  have fsurj : function.surjective f,
  { rintro ⟨e, he⟩,
    induction e using sym2.ind with u₁ u₂,
    cases is_rootward_or_reverse h root he with hr hr,
    { use u₁,
      { rintro rfl,
        dsimp only [is_rootward] at hr,
        exact path.nonempty_path_not_loop _ hr.2, },
      { cases hr,
        simp only [f],
        erw eq_next_edge_if_mem_path _ ⟨he, _⟩ _ hr_right;
        simp [he] } },
    { use u₂,
      { rintro rfl,
        dsimp only [is_rootward] at hr,
        exact path.nonempty_path_not_loop _ hr.2, },
      { cases hr,
        simp only [f],
        erw eq_next_edge_if_mem_path _ ⟨_ , _⟩ _ hr_right;
        simp [he, sym2.eq_swap] } } },
  exact (card_of_bijective ⟨finj, fsurj⟩).symm,
end

end simple_graph
