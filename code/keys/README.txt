CampusCare - the keys folder
============================

Everything that belongs to YOUR accounts goes in this folder, and nowhere
else in the project.

  keys.env              Your Firebase values and the address of your hosted
                        AI service. Open it with any text editor.

  serviceAccount.json   Not here yet. You download it from YOUR Firebase
                        project and save it in this folder with exactly this
                        name. It is the one real secret of the project:
                        whoever holds it has full control of your database.
                        Never send it to anyone, never post it, never upload
                        it to GitHub.

You do not need this folder to run the project on your own computer.
It is used only when you connect your own Firebase project and host the
AI service.

Full instructions:

  guidelines/04-keys/Keys-and-Environment.pdf
  guidelines/05-firebase/Firebase-Setup-Guide.pdf
  guidelines/06-hosting/Hosting-and-Deployment-Guide.pdf
