(*
 * Copyright 2014, General Dynamics C4 Systems
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(GD_GPL)
 *)

(* 
Functions to access kernel memory.
*)

header {* Accessing the Kernel Heap *}

theory KHeap_A
imports Exceptions_A
begin

text {* This theory gives auxiliary getter and setter methods
for kernel objects. *}

section "General Object Access"

definition
  get_object :: "obj_ref \<Rightarrow> (kernel_object,'z::state_ext) s_monad"
where
  "get_object ptr \<equiv> do
     kh \<leftarrow> gets kheap;
     assert (kh ptr \<noteq> None);
     return $ the $ kh ptr
   od"

definition
  set_object :: "obj_ref \<Rightarrow> kernel_object \<Rightarrow> (unit,'z::state_ext) s_monad"
where
  "set_object ptr obj \<equiv> do
     s \<leftarrow> get;
     kh \<leftarrow> return $ (kheap s)(ptr := Some obj);
     put (s \<lparr> kheap := kh \<rparr>)
   od"


section "TCBs"

definition
  get_tcb :: "obj_ref \<Rightarrow> 'z::state_ext state \<Rightarrow> tcb option"
where
  "get_tcb tcb_ref state \<equiv>
   case kheap state tcb_ref of
      None      \<Rightarrow> None
    | Some kobj \<Rightarrow> (case kobj of
        TCB tcb \<Rightarrow> Some tcb
      | _       \<Rightarrow> None)"

definition
  thread_get :: "(tcb \<Rightarrow> 'a) \<Rightarrow> obj_ref \<Rightarrow> ('a,'z::state_ext) s_monad"
where
  "thread_get f tptr \<equiv> do
     tcb \<leftarrow> gets_the $ get_tcb tptr;
     return $ f tcb
   od"

definition
  thread_set :: "(tcb \<Rightarrow> tcb) \<Rightarrow> obj_ref \<Rightarrow> (unit,'z::state_ext) s_monad"
where
  "thread_set f tptr \<equiv> do
     tcb \<leftarrow> gets_the $ get_tcb tptr;
     set_object tptr $ TCB $ f tcb
   od"

definition
  get_thread_state :: "obj_ref \<Rightarrow> (thread_state,'z::state_ext) s_monad" 
where
  "get_thread_state ref \<equiv> thread_get tcb_state ref"

definition set_thread_state_ext :: "obj_ref \<Rightarrow> unit det_ext_monad" where
  "set_thread_state_ext t \<equiv> do
     ts \<leftarrow> get_thread_state t;
     cur \<leftarrow> gets cur_thread;
     action \<leftarrow> gets scheduler_action;
     when (\<not> (runnable ts) \<and> cur = t \<and> action = resume_cur_thread) (set_scheduler_action choose_new_thread)
   od"

definition
  set_thread_state :: "obj_ref \<Rightarrow> thread_state \<Rightarrow> (unit,'z::state_ext) s_monad" 
where
  "set_thread_state ref ts \<equiv> do
     tcb \<leftarrow> gets_the $ get_tcb ref;
     set_object ref (TCB (tcb \<lparr> tcb_state := ts \<rparr>));
     do_extended_op (set_thread_state_ext ref)
   od"

definition
  set_priority :: "obj_ref \<Rightarrow> priority \<Rightarrow> unit det_ext_monad" where
  "set_priority tptr prio \<equiv> do
     tcb_sched_action tcb_sched_dequeue tptr;
     thread_set_priority tptr prio;
     ts \<leftarrow> get_thread_state tptr;
     when (runnable ts) $ tcb_sched_action tcb_sched_enqueue tptr;
     cur \<leftarrow> gets cur_thread;
     when (tptr = cur) reschedule_required
   od"

section {* Synchronous and Asyncronous Endpoints *}

definition
  get_endpoint :: "obj_ref \<Rightarrow> (endpoint,'z::state_ext) s_monad"
where
  "get_endpoint ptr \<equiv> do
     kobj \<leftarrow> get_object ptr;
     (case kobj of Endpoint e \<Rightarrow> return e
                 | _ \<Rightarrow> fail)
   od"

definition
  set_endpoint :: "obj_ref \<Rightarrow> endpoint \<Rightarrow> (unit,'z::state_ext) s_monad"
where
  "set_endpoint ptr ep \<equiv> do
     obj \<leftarrow> get_object ptr;
     assert (case obj of Endpoint ep \<Rightarrow> True | _ \<Rightarrow> False);
     set_object ptr (Endpoint ep)
   od"

definition
  get_async_ep :: "obj_ref \<Rightarrow> (async_ep,'z::state_ext) s_monad"
where
  "get_async_ep ptr \<equiv> do
     kobj \<leftarrow> get_object ptr;
     case kobj of AsyncEndpoint e \<Rightarrow> return e
                 | _ \<Rightarrow> fail
   od"

definition
  set_async_ep :: "obj_ref \<Rightarrow> async_ep \<Rightarrow> (unit,'z::state_ext) s_monad"
where
  "set_async_ep ptr aep \<equiv> do
     obj \<leftarrow> get_object ptr;
     assert (case obj of AsyncEndpoint aep \<Rightarrow> True | _ \<Rightarrow> False);
     set_object ptr (AsyncEndpoint aep)
   od"


section {* IRQ State and Slot *}

definition
  get_irq_state :: "irq \<Rightarrow> (irq_state,'z::state_ext) s_monad" where
 "get_irq_state irq \<equiv> gets (\<lambda>s. interrupt_states s irq)"

definition
  set_irq_state :: "irq_state \<Rightarrow> irq \<Rightarrow> (unit,'z::state_ext) s_monad" where
 "set_irq_state state irq \<equiv> do
    modify (\<lambda>s. s \<lparr> interrupt_states := (interrupt_states s) (irq := state)\<rparr>);
    do_machine_op $ maskInterrupt (state = IRQInactive) irq
  od"

definition
  get_irq_slot :: "irq \<Rightarrow> (cslot_ptr,'z::state_ext) s_monad" where
 "get_irq_slot irq \<equiv> gets (\<lambda>st. (interrupt_irq_node st irq, []))"


section "User Context"

text {* 
  Changes user context of specified thread by running 
  specified user monad.
*}
definition
  as_user :: "obj_ref \<Rightarrow> 'a user_monad \<Rightarrow> ('a,'z::state_ext) s_monad"
where
  "as_user tptr f \<equiv> do
    tcb \<leftarrow> gets_the $ get_tcb tptr;
    uc \<leftarrow> return $ tcb_context tcb;
    (a, uc') \<leftarrow> select_f $ f uc;
    new_tcb \<leftarrow> return $ tcb \<lparr> tcb_context := uc' \<rparr>;
    set_object tptr (TCB new_tcb);
    return a
  od"

end
