
# ULift
This is the open-source repository of the app [ULift](https://play.google.com/store/apps/details?id=cefetmg.br.ulift&hl=pt-BR).

*-Note this repo may contain an error or two because it's not always updated with the latest changes from the original project-*

ULift is an app of sympathetic rides that connects drivers with free seats in cars and riders that have similar itineraries, without profit in mind. It's main goal is to facilitate the life of students and employees in a sustainable manner at academic environments. Initially it's made to work at [CEFET-MG Campus V](http://www.divinopolis.cefetmg.br/) .

Why ride with ULift?  

ULift offers security to users, the app access is made through login, being restricted to people in the university community. Besides that, you are the one to choose to who you want to offer ride, and with whou you want to ride, based in custom filters and ratings. All that is made through real-time updates, that facilitate communication between users.

This app was developed as an undergraduate thesis at [CEFET-MG - Campus V (Divinópolis)](http://www.divinopolis.cefetmg.br/)  by:

[Ariane Amorim ](http://lattes.cnpq.br/5002582904802285),
[Eduardo Amaral ](https://linktr.ee/rolimans),
[Henrique Silva Rabelo](http://lattes.cnpq.br/2015063976359486).

The students were oriented by the professor [Alisson Marques](http://lattes.cnpq.br/3856358583630209) and co-oriented by [Leonardo Gomes]( http://lattes.cnpq.br/7811891165596111).

# SETUP PROCESS
In order to get the app up and running you have to follow these steps:

 - Download the files of this git repo.
 - [Setup Flutter in your PC.](https://flutter.dev/docs/get-started/install)
 - [Create a firebase project](https://console.firebase.google.com/?hl=pt-BR)
 - [Get a Google Maps API Key](https://developers.google.com/maps/documentation/embed/get-api-key)
 - [Create an OneSignal Project](https://onesignal.com/)
 - Create a Telegram Bot with [BotFather](https://core.telegram.org/bots)
 - *Optional -* Setup an [Android Channel at Onesignal](https://documentation.onesignal.com/docs/android-notification-categories) with Heads-Up notifications.
 - Your Flutter app files are located at the folder *flutter-app*
 - In the files located at the *flutter-app* folder replace the following with the respective info:
 
<code>YOUR GOOGLE MAPS API<br>
YOUR ONESIGNAL API<br>
YOUR FIREBASE STORAGE URL<br>
YOUR FIREBASE CLOUD FUNCTIONS URL<br>
YOUR GOOGLESERVICE JSON HERE *(file*)<br>
YOUR GOOGLESERVICE INFO PLIST HERE (*file*)<br>
YOUR URL SCHEME HERE</code>

- Configure Cloud Functions at firebase. The functions you need are in the *cloud-functions* folder.
- In the files located at the *cloud-functions* folder replace the following with the respective info:

<code>YOUR GOOGLE MAPS API<br>
YOUR PROJECT
</code>

- Setup a Node JS server to run the `index.js` alongside it's project files located at the *server-functions* folder.
- In the files located at the *server-functions* folder replace the following with the respective info:

<code>YOUR GOOGLE SERVICE KEY FIREBASE HERE (*file*)<br>
YOUR TELEGRAM API KEY<br>
YOUR ONESIGNAL USER AUTH KEY<br>
YOUR ONESIGNAL APP AUTH KEY<br>
YOUR ONESIGNAL APP ID<br>
YOUR DATABASE URL<br>
YOUR ONESIGNAL ANDROID CHANNEL ID
</code>

- [Finnally add your SHA-1 fingerprintin your firebase project.](https://support.google.com/firebase/answer/9137403?hl=en&ref_topic=6400762)


***THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.***
