(*
 * Copyright 2014, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(NICTA_BSD)
 *)

(* Backend for tracing apply statements. Useful for doing proof step dependency analysis.
 * Provides an alternate refinement function which takes an additional stateful journaling operation. *)
theory Apply_Trace
imports Main
begin


ML {*
signature APPLY_TRACE =
sig
val apply_results : 
  {localize_facts : bool, silent_fail : bool} ->
  (Proof.context -> Method.text -> thm -> (string * term) list -> unit) -> 
  Method.text_range -> Proof.state -> Proof.state Seq.result Seq.seq

val mentioned_facts: Method.text -> thm list

end

structure Apply_Trace : APPLY_TRACE =
struct

fun thm_to_cterm thm =
let
  
  val thy = Thm.theory_of_thm thm
  val crep = crep_thm thm
  val ceqs = map (Thm.cterm_of thy o Logic.mk_equals o pairself term_of) (#tpairs crep)

in
  Drule.list_implies (ceqs,#prop crep) end


val (_, clear_thm_deps') =
  Context.>>> (Context.map_theory_result (Thm.add_oracle (Binding.name "count_cheat", thm_to_cterm)));

fun clear_deps thm =
let
   
  val thm' = try clear_thm_deps' thm
  |> Option.map (fold (fn _ => fn t => (@{thm Pure.reflexive} RS t)) (#tpairs (rep_thm thm)))

in case thm' of SOME thm' => thm' | NONE => error "Can't clear deps here" end


fun can_clear thy = Theory.subthy(@{theory},thy)

fun join_deps thm thm' = Conjunction.intr thm thm' |> Conjunction.elim |> snd 

fun thms_of (PBody {thms,...}) = thms

fun proof_body_descend' (_,("",_,body)) = fold (append o proof_body_descend') (thms_of (Future.join body)) []
  | proof_body_descend' (_,(nm,t,_)) = [(nm,t)]


fun used_facts thm = fold (append o proof_body_descend') (thms_of (Thm.proof_body_of thm)) []

fun raw_primitive_text f = Method.Basic (K (Method.RAW_METHOD (K (fn thm => Seq.single (f thm)))))


fun fold_map_src f m =
let
  fun fold_map' m' a = case m' of
   Method.Source src => let val (src',a') = (f src a) in (Method.Source src',a') end
 | (Method.Source_i src) => let val (src',a') = (f src a) in (Method.Source_i src',a') end
 | (Method.Then ms) => let val (ms',a') = fold_map fold_map' ms a in (Method.Then ms',a') end
 | (Method.Orelse ms) => let val (ms',a') = fold_map fold_map' ms a in (Method.Orelse ms',a') end
 | (Method.Try m) => let val (m',a') = fold_map' m a in (Method.Try m',a') end
 | (Method.Repeat1 m) => let val (m',a') = fold_map' m a in (Method.Repeat1 m',a') end
 | (Method.Select_Goals (i,m)) => let val (m',a') = fold_map' m a in (Method.Select_Goals (i,m'),a') end
 | (Method.Basic g) => (Method.Basic g,a)
in
  fold_map' m end

fun map_src f text = fold_map_src (fn src => fn () => (f src,())) text () |> fst

fun fold_src f text a = fold_map_src (fn src => fn a => (src,f src a)) text a |> snd

fun mentioned_facts_src src = 
let
  val ((name,toks),pos) = Args.dest_src src
  val thms = fold ((fn (SOME (Token.Fact f)) => append f | _ => I) o Token.get_value) toks []
in
  thms end


fun mentioned_facts text = fold_src (append o mentioned_facts_src) text []

(*Give local facts (from "have" or locale assumptions)
  the most local name possible before processing method*)
fun name_local_facts ctxt =
let
  val facts = Proof_Context.facts_of ctxt
  fun name_thm thm = Thm.name_derivation (Thm.get_name_hint thm) thm

  fun name_fact (name,fact) = (Facts.extern ctxt facts name,SOME (map name_thm fact))
  val facts' = map name_fact (facts |> Facts.dest_static [])
in
  fold (Proof_Context.put_thms true) facts' ctxt end

(* Perform refinement step, and run the given stateful function
   against computed dependencies afterwards. *)
fun refine args f text state =
let
  val state' = if (#localize_facts args) 
  then (Proof.map_context name_local_facts state)
  else state

  val thm = Proof.simple_goal state |> #goal

  val text' = map_src Args.assignable text

  fun save_deps deps = f (Proof.context_of state) (map_src Args.closure text') thm deps
  
in
 if (can_clear (Proof.theory_of state')) then  
   Proof.refine (Method.Then [raw_primitive_text clear_deps,text',
	raw_primitive_text (fn thm' => (save_deps (used_facts thm');join_deps thm thm'))]) state'
 else
   (if (#silent_fail args) then (save_deps [];Proof.refine text state) else error "Apply_Trace theory must be imported to trace applies")
end

(* Boilerplate from Proof.ML *)


fun method_error kind pos state =
  Seq.single (Proof_Display.method_error kind pos (Proof.raw_goal state));

fun apply args f text = Proof.assert_backward #> refine args f text #> Seq.maps (Proof.apply (raw_primitive_text I));

fun apply_results args f (text, range) =
  Seq.APPEND (apply args f text #> Seq.make_results, method_error "" (Position.set_range range));


end
*}

end

