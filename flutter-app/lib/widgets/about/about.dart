import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pimp_my_button/pimp_my_button.dart';
import 'package:ulift/config/shared_data.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int counter = 0;

  @override
  void initState() {
    CurrentPage.page = Page.about;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sobre'),
        ),
        body: Builder(
          builder: (context) => ListView(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(
                  top: 32.0,
                  bottom: 16.0,
                ),
                child: PimpedButton(
                  duration: Duration(seconds: 1),
                  particle: CompositeParticle(
                      children: [MyCustomParticle(), Rectangle3DemoParticle()]),
                  pimpedWidgetBuilder: (context, controller) {
                    return GestureDetector(
                      onTap: () {
                        if (counter == 4) {
                          controller.forward(from: 0.0);
                          setState(() {
                            counter = 0;
                          });
                        } else {
                          setState(() {
                            counter++;
                          });
                        }
                      },
                      child: Hero(
                          tag: 'team-pic',
                          child: CircleAvatar(
                              radius: 120.0,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  width: 240,
                                  height: 240,
                                  imageUrl: getImageUrl("equipe"),
                                  placeholder: (context, url) =>
                                      new CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Text(
                                    "!",
                                    style: TextStyle(fontSize: 100.0),
                                  ),
                                ),
                              ))),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  child: Text(
                    "O ULift é um aplicativo de caronas solidárias que conecta motoristas com lugares vazios nos carros e caroneiros que possuem trajetos semelhantes, sem visar lucros. Seu objetivo é facilitar o deslocamento de estudantes e funcionários de forma sustentável em ambientes acadêmicos sendo voltado, inicialmente, para o CEFET-MG - Campus V.\n\nPor que andar de carona com o ULift?\n\nO ULift oferece segurança para os usuários, o acesso é realizado por meio de login, sendo restringido a pessoas da comunidade cefetiana. Além disso, você é quem escolhe com quem deseja oferecer ou pegar carona, baseado em filtros personalizados e avaliações. Tudo isso é realizado por meio de atualizações em tempo real, que facilitam a comunicação entre os usuários.\n\nEsse aplicativo foi desenvolvimento como TCC no CEFET-MG - Campus V (Divinópolis).",
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Container(
                    child: Text(
                      "Equipe:",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: getImageUrl("ariane"),
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          "A",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      ),
                    )),
                trailing: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.link,
                    size: 20,
                  ),
                  onPressed: () {
                    openUrl("http://lattes.cnpq.br/5002582904802285");
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aluna',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      "Ariane Amorim da Silva",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 0.0,
                indent: 72.0,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: getImageUrl("eduardo"),
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          "E",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      ),
                    )),
                trailing: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.link,
                    size: 20,
                  ),
                  onPressed: () {
                    openUrl("https://rolimans.dev");
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aluno',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      "Eduardo Amaral",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 0.0,
                indent: 72.0,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: getImageUrl("henrique"),
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          "H",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      ),
                    )),
                trailing: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.link,
                    size: 20,
                  ),
                  onPressed: () {
                    openUrl("http://lattes.cnpq.br/2015063976359486");
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aluno',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      "Henrique Silva Rabelo",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 0.0,
                indent: 72.0,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: getImageUrl("alisson"),
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          "A",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      ),
                    )),
                trailing: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.link,
                    size: 20,
                  ),
                  onPressed: () {
                    openUrl("http://lattes.cnpq.br/3856358583630209");
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Orientador',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      "Alisson Marques da Silva",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 0.0,
                indent: 72.0,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: getImageUrl("leo"),
                        placeholder: (context, url) =>
                            new CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          "L",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      ),
                    )),
                trailing: IconButton(
                  icon: Icon(
                    FontAwesomeIcons.link,
                    size: 20,
                  ),
                  onPressed: () {
                    openUrl("http://lattes.cnpq.br/7811891165596111");
                  },
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Coorientador',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                      ),
                    ),
                    Text(
                      "Leonardo Gomes Martins Coelho",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                      ),
                    )
                  ],
                ),
              ),
              Divider(
                height: 0.0,
                indent: 72.0,
              ),
              Padding(
                padding: EdgeInsets.all(16),
              )
            ],
          ),
        ));
  }
}

String getImageUrl(String name) {
  return "YOUR FIREBASE STORAGE URL/o/docs%2Fpics%2F$name.png?alt=media";
}

void openUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    Crashlytics.instance.log("UNABLE TO LAUNCH URL");
  }
}

class MyCustomParticle extends Particle {
  @override
  void paint(Canvas canvas, Size size, progress, seed) {
    CompositeParticle(children: [
      Firework(),
      Firework(),
      Firework(),
      RectangleMirror.builder(
          numberOfParticles: 20,
          particleBuilder: (int) {
            return AnimatedPositionedParticle(
              begin: Offset(0.0, -30.0),
              end: Offset(0.0, -80.0),
              child:
                  FadingRect(width: 5.0, height: 15.0, color: intToColor(int)),
            );
          },
          initialDistance: 0.0),
      RectangleMirror.builder(
          numberOfParticles: 15,
          particleBuilder: (int) {
            return AnimatedPositionedParticle(
              begin: Offset(0.0, -25.0),
              end: Offset(0.0, -60.0),
              child:
                  FadingRect(width: 5.0, height: 15.0, color: intToColor(int)),
            );
          },
          initialDistance: 30.0),
      RectangleMirror.builder(
          numberOfParticles: 20,
          particleBuilder: (int) {
            return AnimatedPositionedParticle(
              begin: Offset(0.0, -40.0),
              end: Offset(0.0, -100.0),
              child:
                  FadingRect(width: 5.0, height: 15.0, color: intToColor(int)),
            );
          },
          initialDistance: 80.0),
    ]).paint(canvas, size, progress, seed);
  }
}
