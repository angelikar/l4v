(*
 * Copyright 2014, General Dynamics C4 Systems
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(GD_GPL)
 *)

header "Function Declarations for Threads"

theory ThreadDecls_H
imports
  Structures_H
  FaultMonad_H
  KernelInitMonad_H
  ArchThreadDecls_H
begin

consts
configureIdleThread :: "machine_word \<Rightarrow> unit kernel_init"

consts
activateInitialThread :: "machine_word \<Rightarrow> vptr \<Rightarrow> vptr \<Rightarrow> unit kernel"

consts
activateThread :: "unit kernel"

consts
isBlocked :: "machine_word \<Rightarrow> bool kernel"

consts
isRunnable :: "machine_word \<Rightarrow> bool kernel"

consts
suspend :: "machine_word \<Rightarrow> unit kernel"

consts
restart :: "machine_word \<Rightarrow> unit kernel"

consts
doIPCTransfer :: "machine_word \<Rightarrow> (machine_word) option \<Rightarrow> machine_word \<Rightarrow> bool \<Rightarrow> machine_word \<Rightarrow> bool \<Rightarrow> unit kernel"

consts
doReplyTransfer :: "machine_word \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> unit kernel"

consts
doNormalTransfer :: "machine_word \<Rightarrow> (machine_word) option \<Rightarrow> (machine_word) option \<Rightarrow> machine_word \<Rightarrow> bool \<Rightarrow> machine_word \<Rightarrow> (machine_word) option \<Rightarrow> bool \<Rightarrow> unit kernel"

consts
doFaultTransfer :: "machine_word \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> (machine_word) option \<Rightarrow> unit kernel"

consts
transferCaps :: "message_info \<Rightarrow> (capability * machine_word) list \<Rightarrow> (machine_word) option \<Rightarrow> machine_word \<Rightarrow> (machine_word) option \<Rightarrow> bool \<Rightarrow> message_info kernel"

consts
doAsyncTransfer :: "machine_word \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> unit kernel"

consts
schedule :: "unit kernel"

consts
chooseThread :: "unit kernel"

consts
switchToThread :: "machine_word \<Rightarrow> unit kernel"

consts
switchToIdleThread :: "unit kernel"

consts
setDomain :: "machine_word \<Rightarrow> domain \<Rightarrow> unit kernel"

consts
setPriority :: "machine_word \<Rightarrow> priority \<Rightarrow> unit kernel"

consts
possibleSwitchTo :: "machine_word \<Rightarrow> bool \<Rightarrow> unit kernel"

consts
attemptSwitchTo :: "machine_word \<Rightarrow> unit kernel"

consts
switchIfRequiredTo :: "machine_word \<Rightarrow> unit kernel"

consts
rescheduleRequired :: "unit kernel"

consts
getThreadState :: "machine_word \<Rightarrow> thread_state kernel"

consts
setThreadState :: "thread_state \<Rightarrow> machine_word \<Rightarrow> unit kernel"

consts
tcbSchedEnqueue :: "machine_word \<Rightarrow> unit kernel"

consts
tcbSchedAppend :: "machine_word \<Rightarrow> unit kernel"

consts
tcbSchedDequeue :: "machine_word \<Rightarrow> unit kernel"

consts
timerTick :: "unit kernel"


end
