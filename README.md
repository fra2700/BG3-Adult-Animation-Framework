Installation:
-

1. Norbyte's Baldur's Gate 3 Script Extender from here: https://github.com/Norbyte/bg3se/releases
   - If you are using the ModManager you can install it from there, but its better to always grab the newest version from github and add the DWrite.dll to your "Baldurs Gate 3/bin" folder
  
2. Install BG3 Mod Manager (BG3MM): https://github.com/LaughingLeader/BG3ModManager

3. Uninstall all loose files installed with a previous version of the mod
   a. Navigate to your \Baldurs Gate 3\Data Directory, typically:  
      "C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3"
   b. Delete the following folders if they are found:
     - "Baldurs Gate 3\Data\Mods\AnimationFramework"
     - "Baldurs Gate 3\Data\Public\AnimationFramework"
     - "Baldurs Gate 3\Data\Public\Shared\Assets\Characters\_Anims"

5. Download both of the 'main' mod files:
     - AnimationFrameworkPak.zip
     - BG3-AnimLoader.zip

6. Install the AnimationFramework.pak file with BG3MM:
    - Drag AnimationFrameworkPak.zip into BG3MM. It will appear in the panel opn the right hand side.
    - Drag 'AnimationFramework' from the right hand side of BG3MM. (1)
    - Press the 'Save Load Orderto File' button to save your mod load order, or just press 'ctrl + s' (2)
    - Now press the 'Export Order to Game' button to deploy your mod load order to your game, or just press 'ctrl + e' (3)

    
![Screenshot 2024-02-09 170757](https://github.com/LuneMods/BG3-Adult-Animation-Framework/assets/155053912/0d929ed6-2546-4dcb-819a-0497de407db8)


7. Copy the contents of BG3-Animloader.zip to "C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Tools"
   - BG3-AnimLoader.exe should now be located here: "C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Tools\BG3-AnimLoader\BG3-AnimLoader.exe
  
8. Open BG3-Animloader.exe
   - A pop may appear telling you to locate 'Divine.exe'. Navigate to "C:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Tools\BG3-AnimLoader\LSlib\Divine.exe"
   - Divine.exe is a utility created by LaughingLeader that allows game files to be converted to readable/editable format, and has been included with BG3-AnimLoader.

  
     ![Screenshot 2024-02-09 171127](https://github.com/LuneMods/BG3-Adult-Animation-Framework/assets/155053912/7ef9b466-8ec9-4405-8df3-3439b000fedb)


        ![Screenshot 2024-02-09 171155](https://github.com/LuneMods/BG3-Adult-Animation-Framework/assets/155053912/2173bfa1-96e6-499a-8314-09bca2bea606)


9. Press 'Install Animations' in the bottom right. This will generate the required files for the animations that are contained within the "BG3-AnimLoader\LSlib\Animations" folder.
  

      ![Screenshot 2024-02-09 171413](https://github.com/LuneMods/BG3-Adult-Animation-Framework/assets/155053912/792b99ad-ab94-4884-b18e-3c972a4d7551)



10. Done! Test the animations in game. If you have any further issues with the installation, join the Discord Server and post in the '#support' channel: https://discord.gg/vbP4EyCyRt
