import ij.*;
import ij.process.*;
import ij.gui.*;
import java.awt.*;
import ij.plugin.*;
import ij.plugin.frame.*;
//This is the interface for all scripts presented by the lab
//the quantification macro will be one of the scripts
//in the future will be able to update this script remotely
public class Sulkowski_Lab implements PlugIn
{
	String directory = "";
	String quantMacroName = "AIABS";
	String macroFileName = "AIABS.ijm";
	String macroDirectory = "";
	public void run(String arg)
	{
		//get the directory
		directory = IJ.getDir("imagej");
		//get the macro directory
		macroDirectory = directory +"/macros/";
		CreateLabDialog();
	}
	void CreateLabDialog()
	{
	GenericDialog gd = new GenericDialog("Sulkowski Lab");
	String [] items = new String []
	{
			"AIABS","SAP"
	};
	 gd.addChoice("Run Script",items, items[0]);
	 gd.showDialog();
	 String choice = gd.getNextChoice();
	 if(choice == "AIABS")
	 {
	 	OpenQuantMacro();
	 }else if (choice == "SAP")
	 {
	 		OpenSAP();
	 }
	}
	void OpenQuantMacro()
	{
		//assign the macro path string
		String macroPath = macroDirectory + macroFileName;
		//open the quantification macro
		IJ.runMacroFile(macroPath);
	}
	void OpenSAP()
	{
		String SAPOpenCMD = "C:/Users/Jeremy/PycharmProjects/LearningToDraw/venv/Scripts/dist/SAP 1/Resources/main.exe";
		IJ.run("exec("+ SAPOpenCMD+")");
	}
}
