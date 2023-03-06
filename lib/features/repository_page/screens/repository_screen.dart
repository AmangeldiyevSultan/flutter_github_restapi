import 'package:flutter/material.dart';
import 'package:flutter_github/common/utils/colors.dart';
import 'package:flutter_github/common/utils/utils.dart';
import 'package:flutter_github/common/wdigets/custom_button.dart';
import 'package:flutter_github/common/wdigets/error_state.dart';
import 'package:flutter_github/common/wdigets/loader.dart';
import 'package:flutter_github/features/auth/services/auth_services.dart';
import 'package:flutter_github/features/repository_page/screens/create_issue_screen.dart';
import 'package:flutter_github/features/repository_page/screens/issues_page.dart';
import 'package:flutter_github/features/repository_page/services/repository_services.dart';
import 'package:flutter_github/features/repository_page/widgets/span_icon_text.dart';
import 'package:flutter_github/models/readme_model.dart';
import 'package:flutter_github/models/repository_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/link.dart';

class RepositoryScreen extends StatefulWidget {
  static const String routeName = '/repository-screen';
  final RepositoryModel repositoryModel;
  const RepositoryScreen({super.key, required this.repositoryModel});

  @override
  State<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends State<RepositoryScreen> {
  AuthServices authServices = AuthServices();
  RepositoryServices repositoryServices = RepositoryServices();
  String link = '';
  String license = '';
  @override
  void initState() {
    super.initState();
    link = widget.repositoryModel.htmlUrl!
        .substring(widget.repositoryModel.htmlUrl!.indexOf('g'));
    license = widget.repositoryModel.license != null
        ? '${widget.repositoryModel.license!['key']}'.toCapitalized()
        : '';
  }

  void navigateToCreateIssuePage() {
    Navigator.pushNamed(context, CreateIssueScreen.routeName,
        arguments: widget.repositoryModel.url);
  }

  void navigateToIssuePage() {
    Navigator.pushNamed(context, IssuePage.routeName,
        arguments: widget.repositoryModel.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: kArrowBackColor,
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.repositoryModel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                authServices.logOut(context: context);
              },
              child: const Icon(
                Icons.exit_to_app,
                size: 30,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24, left: 18, right: 18),
        child: Column(children: [
          Link(
              target: LinkTarget.blank,
              uri: Uri.parse(widget.repositoryModel.htmlUrl!),
              builder: (context, followLink) {
                return GestureDetector(
                  onTap: followLink,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: kLinkColor,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Flexible(
                        child: Text(
                          link,
                          style: const TextStyle(
                              overflow: TextOverflow.ellipsis,
                              color: kLinkColor,
                              fontSize: 16),
                        ),
                      )
                    ],
                  ),
                );
              }),
          const SizedBox(
            height: 27.5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/images/license_icon.svg'),
                  const SizedBox(width: 5),
                  const Text(
                    'License',
                    style: TextStyle(fontSize: 16),
                  )
                ],
              ),
              Text(
                license,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SpanIconText(
                text: 'stars',
                icon: Icons.star,
                color: kStarColor,
                amount: widget.repositoryModel.score.toInt(),
              ),
              SpanIconText(
                text: 'forks',
                assetLink: 'assets/images/fork_icon.svg',
                color: kForkAndQuestionColor,
                amount: widget.repositoryModel.forks,
              ),
              SpanIconText(
                text: 'watchers',
                icon: Icons.visibility,
                color: kWatcherColor,
                amount: widget.repositoryModel.watchers,
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SpanIconText(
                text: 'Issues',
                assetLink: 'assets/images/question_icon.svg',
                color: kForkAndQuestionColor,
                amount: widget.repositoryModel.openIssuesCount,
              ),
              GestureDetector(
                onTap: navigateToIssuePage,
                child: const Text(
                  'View issues',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 26.5,
          ),
          FutureBuilder(
              future: repositoryServices.fetchReadMe(
                  context: context, contentUrl: widget.repositoryModel.url!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.none) {
                  return StateErrorCondition(
                    stateEnum: StateEnum.loadError,
                    onTap: () {
                      setState(() {});
                    },
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                }
                if (snapshot.data!.statusCode == null) {
                  return Expanded(
                    child: StateErrorCondition(
                      stateEnum: StateEnum.loadError,
                      onTap: () {
                        setState(() {});
                      },
                    ),
                  );
                }
                if (snapshot.data!.statusCode != 200) {
                  return const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No README.md',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ));
                }
                ReadMeModel readMeContent = snapshot.data!;
                List<String> content = convertBase64(
                    readMeContent.content!, readMeContent.encoding!);
                return Expanded(
                  child: Stack(children: [
                    ListView(
                      children: [
                        RichText(
                            text: TextSpan(
                          children: List.generate(
                              content.length,
                              (index) => TextSpan(
                                  text: content[index],
                                  style: TextStyle(
                                      fontWeight: content[index].startsWith('#')
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: content[index].startsWith('#')
                                          ? 23
                                          : 16))),
                        )),
                      ],
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 20),
                          child: CustomButton(
                              text: 'Create new issue',
                              onTap: navigateToCreateIssuePage),
                        ))
                  ]),
                );
              }),
        ]),
      ),
    );
  }
}
