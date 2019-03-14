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
	String macroFileName = "AIABS.ijm";
	String pluginDirectory = "";
	public void run(String arg)
	{
		//get the directory
		directory = IJ.getDir("imagej");
		//get the macro directory
		pluginDirectory = directory +"/plugins/";
		OpenQuantMacro();

	}
	void OpenQuantMacro()
	{
		//assign the macro path string
		String macroPath = pluginDirectory + macroFileName;
		//open the quantification macro
		IJ.runMacroFile(macroPath);
	}
}
