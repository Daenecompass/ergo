(*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

(* This module contains a few basic utilities *)
open Monitor_j (* For the monitor JSON output *)

(* this can't go in Logger, since that creates a circular dependency *)
type nrc_logger_token_type = string

(** Conversions *)
let string_of_char_list l =
  let b = Bytes.create (List.length l) in
  let i = ref 0 in
  List.iter (fun c -> Bytes.set b !i c; incr i) l;
  Bytes.to_string b

let char_list_of_string s =
  let rec exp i l =
    if i < 0 then l else exp (i - 1) (s.[i] :: l) in
  exp (String.length s - 1) []

let char_list_append s1 s2 =
  char_list_of_string ((string_of_char_list s1) ^ (string_of_char_list s2))

let coq_Z_of_int i = i


(** I/O *)
let os_newline = "\n"
let string_of_file file =
  try
    let inchan = open_in_bin file in
    let len = in_channel_length inchan in
    let buf = Buffer.create len in
    Buffer.add_channel buf inchan len;
    close_in inchan;
    Buffer.contents buf
  with
    Sys_error err ->
      Printf.eprintf
        "Could not read the file %s, got error Sys_error %s\n@?"
        file
        err;
      raise (Sys_error err)

(** File print *)
let make_file fout scomp =
  let oc = open_out fout in
  begin
    output_string oc scomp;
    close_out oc
  end

(** Make up target file name *)
let target_f dir f =
  begin match dir with
  | None -> f
  | Some d ->
      Filename.concat d (Filename.basename f)
  end

let outname f suff = f ^ suff

(** Support for Enhanced operators *)

let float_sum l =
  List.fold_left (+.) 0. l

(* note that this is inefficient, becase it uses two passes over the list *)
let float_arithmean l =
  let ll = List.length l in
  if(ll == 0)
  then 0.
  else List.fold_left (+.) 0. l /. (float ll)

let rec float_listmin_aux l x =
  begin match l with
  | [] -> x
  | c :: ls -> float_listmin_aux ls (if x<c then x else c)
  end

let float_listmin l =
  begin match l with
  | [] -> infinity
  | c :: ls -> float_listmin_aux ls c
  end

let rec float_listmax_aux l x =
  begin match l with
  | [] -> x
  | c :: ls -> float_listmax_aux ls (if x>c then x else c)
  end

let float_listmax l =
  begin match l with
  | [] -> neg_infinity
  | c :: ls -> float_listmax_aux ls c
  end

let qcert_string_of_float f =
  let ocaml_string1 = Printf.sprintf "%.17g" f in (* XXX TO BE REVIEWED *)
  let ocaml_string2 = Printf.sprintf "%.16g" f in (* XXX TO BE REVIEWED *)
  let ocaml_string =
    if (float_of_string ocaml_string1 = float_of_string ocaml_string2)
    then ocaml_string2 else ocaml_string1
  in
  let last_char = ocaml_string.[(String.length ocaml_string)-1] in
  begin match last_char with
  | '.' -> ocaml_string ^ "0"
  | _ -> ocaml_string
  end

let string_of_enhanced_float f = char_list_of_string (string_of_float f)
let string_of_enhanced_string s = char_list_of_string ("S\"" ^ s ^ "\"")

(**********************************)
(* Timing function for CompStat   *)
(**********************************)

let time f x =
  let start = Sys.time() in
  let v = f x in
  let stop = Sys.time() in
  let t = string_of_float (stop -. start) in
  (char_list_of_string t, v)

(* String manipulation *)    

let string_before s n = String.sub s 0 n
let string_after s n = String.sub s n (String.length s - n)
let first_chars s n = String.sub s 0 n
let last_chars s n = String.sub s (String.length s - n) n

let re_match re s pos =
  if pos >= String.length s then raise Not_found
  else
    let rec pos_match re s pos_re pos_s =
      if pos_re >= String.length re
      then true
      else
        try
          if re.[pos_re] = s.[pos_s]
          then pos_match re s (pos_re+1) (pos_s+1)
          else false
        with
        | _ -> false
    in
    pos_match re s 0 pos

let search_forward re s pos =
  if re = "" then raise (Invalid_argument "Matching string should not be empty")
  else
    let rec find start =
      if re_match re s start
      then start
      else find (start+1)
    in
    find pos

let opt_search_forward re s pos =
  try Some(search_forward re s pos) with Not_found -> None

let global_replace const_expr repl text =
  let rec replace accu start last_was_empty =
    let startpos = if last_was_empty then start + 1 else start in
    if startpos > String.length text then
      string_after text start :: accu
    else
      begin match opt_search_forward const_expr text startpos with
      | None ->
          string_after text start :: accu
      | Some pos ->
          let end_pos = pos + String.length const_expr in
          let repl_text = repl in
          replace (repl_text :: String.sub text start (pos-start) :: accu)
            end_pos (end_pos = pos)
      end
  in
  String.concat "" (List.rev (replace [] 0 false))

let filename_append dir path =
  List.fold_left Filename.concat dir path

let loc_error s f x =
  begin try f x with
  | Failure exn -> raise (Failure exn)
  | exn -> raise (Failure ("[In " ^ s ^ "]" ^ (Printexc.to_string exn)))
  end

let map_assoc f l =
   List.map (fun xy -> f (fst xy) (snd xy)) l

(** Mini topo-sort *)
(* XXX To be revised when Coq-level DFS-topological sort is complete *)

exception TopoCycle of string list

let dfs label file graph visited start_node = 
  let rec explore path visited node = 
    if List.mem (label node) (List.map label path) then raise (TopoCycle (List.map file (node::path))) else
    if List.mem (label node) (List.map label visited) then visited else     
      let new_path = node :: path in 
      let edges    = List.assoc (label node) (List.map (fun (x,y) -> (label x, y)) graph) in
      let visited  = List.fold_left (explore new_path) visited edges in
      node :: visited
  in explore [] visited start_node

let toposort label file graph = 
  List.rev (List.fold_left (fun visited (node,_) -> dfs label file graph visited node) [] graph)

let coq_toposort label file graph =
  let sorted = toposort label (fun x -> string_of_char_list (file x)) graph in
  (* List.iter (fun x -> Printf.printf "[SORT] %s\n" (string_of_char_list (file x))) sorted; *)
  sorted

let get_local_part name =
  let name = string_of_char_list name in
  begin match String.rindex_opt name '.' with
  | None -> None
  | Some i ->
      let local = String.sub name (i+1) (String.length name - (i+1)) in
      Some (char_list_of_string local)
  end

let class_prefix_of_filename filename =
  begin try
    Filename.chop_extension (Filename.basename filename)
  with
  | Invalid_argument _ -> "logic"
  end

(** Monitoring *)

(* monitor contains a mapping from compilation phase to (f1,f2) where f1 is the new time entering the phase and f2 is the total time in that phase *)
let monitor : (string, float * float) Hashtbl.t = Hashtbl.create 37
let monitoring = ref false
let monitoring_start = Sys.time ()
let monitor_output : (Monitor_j.phase list) Stack.t =
  let s = Stack.create () in
  Stack.push [] s;
  s

let enter_monitor monitor output phase =
  Stack.push [] output;
  begin try
    let (f1,f2) = Hashtbl.find monitor phase in (* f1 should always be 0.0 *)
    Hashtbl.replace monitor phase (Sys.time(), f2)
  with _ ->
    Hashtbl.add monitor phase (Sys.time(), 0.0)
  end
let exit_monitor monitor output phase =
  let prev = Stack.pop output in
  let prevprev = Stack.pop output in
  begin try
    let (f1,f2) = Hashtbl.find monitor phase in
    let picktime : float = Sys.time () in
    let single : float = picktime -. f1 in
    let cummul : float = picktime -. f1 +. f2 in
    let total : float = picktime -. monitoring_start in
    Hashtbl.replace monitor phase (0.0, cummul);
    Stack.push (prevprev @ [{
      monitor_phase_class = "org.accordproject.ergo.monitor.Phase";
      monitor_phase_name = phase;
      monitor_phase_single = single;
      monitor_phase_cummulative = cummul;
      monitor_phase_total = total;
      monitor_phase_subphases =prev
    }]) output
  with _ ->
    begin
      let picktime : float = Sys.time () in
      let single : float = 0.0 in
      let cummul : float = 0.0 in
      let total : float = picktime -. monitoring_start in
      Hashtbl.add monitor phase (0.0, 0.0); (* Should never happen *)
      Stack.push (prevprev @ [{
        monitor_phase_class = "org.accordproject.ergo.monitor.Phase";
        monitor_phase_name = phase;
        monitor_phase_single = single;
        monitor_phase_cummulative = cummul;
        monitor_phase_total = total;
        monitor_phase_subphases = prev
      }]) output
    end
  end

let coq_time phase f x =
  if !monitoring
  then
    let phase = string_of_char_list phase in
    begin
      enter_monitor monitor monitor_output phase;
      let y = f x in
      exit_monitor monitor monitor_output phase;
      y
    end
  else
    f x

let get_monitor_output () =
  string_of_monitor {
    monitor_class = "org.accordproject.ergo.monitor.Monitor";
    monitor_phases = Stack.top monitor_output
  }

