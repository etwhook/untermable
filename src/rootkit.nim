{.passL: "-s -static-libgcc".}
import minhook, winim/lean, strutils

let cantTerminate = ["Discord.exe"]
proc toString(arr : openArray[char]): string =
  var final = ""
  for character in arr:
    if character == '\x00':
      continue
    final.add(character)
  return final

proc NtTerminateProcess(ProcessHandle: HANDLE, ExitStatus: NTSTATUS): NTSTATUS
  {.stdcall, dynlib: "ntdll", importc: "NtTerminateProcess".}
proc GetModuleFileNameExA(
  hProcess: HANDLE,
  hModule: HMODULE,
  lpFileName: LPSTR,
  nSize: DWORD
)  {.stdcall, dynlib: "psapi", importc: "GetModuleFileNameExA".}
proc detour(ProcessHandle: HANDLE, ExitStatus: NTSTATUS): NTSTATUS
  {.stdcall, minhook: NtTerminateProcess.} =
  var name: array[0..MAX_PATH, char]
  GetModuleFileNameExA(
    ProcessHandle,
    cast[HMODULE](NULL),
    cast[LPSTR](&name),
    cast[DWORD](MAX_PATH + 1)
  )
  let name_str = name.toString.split("\\")[^1]
  if name_str in cantTerminate:
    #discard NtTerminateProcess(cast[HANDLE](NULL), STATUS_SUCCESS)
    MessageBox(0, "bra wtf", "YOU WONT TERMINATE ME👿👿.", 0)
    result = cast[NTSTATUS](0x45) # for da lolz
  else:
    result = NtTerminateProcess(ProcessHandle, ExitStatus)

proc main() =
  enableHook(NtTerminateProcess)
  let handle = OpenProcess(PROCESS_ALL_ACCESS, FALSE , 8424)
  let lolStatus = NtTerminateProcess(handle , STATUS_SUCCESS)
  echo(lolStatus)
main()