//
// Vivado(TM)
// rundef.js: a Vivado-generated Runs Script for WSH 5.1/5.6
// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
//

var WshShell = new ActiveXObject( "WScript.Shell" );
var ProcEnv = WshShell.Environment( "Process" );
var PathVal = ProcEnv("PATH");
if ( PathVal.length == 0 ) {
  PathVal = "D:/Xilinx/15.2/SDK/2015.2/bin;D:/Xilinx/15.2/Vivado/2015.2/ids_lite/ISE/bin/nt64;D:/Xilinx/15.2/Vivado/2015.2/ids_lite/ISE/lib/nt64;D:/Xilinx/15.2/Vivado/2015.2/bin;";
} else {
  PathVal = "D:/Xilinx/15.2/SDK/2015.2/bin;D:/Xilinx/15.2/Vivado/2015.2/ids_lite/ISE/bin/nt64;D:/Xilinx/15.2/Vivado/2015.2/ids_lite/ISE/lib/nt64;D:/Xilinx/15.2/Vivado/2015.2/bin;" + PathVal;
}

ProcEnv("PATH") = PathVal;

var RDScrFP = WScript.ScriptFullName;
var RDScrN = WScript.ScriptName;
var RDScrDir = RDScrFP.substr( 0, RDScrFP.length - RDScrN.length - 1 );
var ISEJScriptLib = RDScrDir + "/ISEWrap.js";
eval( EAInclude(ISEJScriptLib) );


ISEStep( "vivado",
         "-log dsp48_mul_ip.vds -m64 -mode batch -messageDb vivado.pb -notrace -source dsp48_mul_ip.tcl" );



function EAInclude( EAInclFilename ) {
  var EAFso = new ActiveXObject( "Scripting.FileSystemObject" );
  var EAInclFile = EAFso.OpenTextFile( EAInclFilename );
  var EAIFContents = EAInclFile.ReadAll();
  EAInclFile.Close();
  return EAIFContents;
}