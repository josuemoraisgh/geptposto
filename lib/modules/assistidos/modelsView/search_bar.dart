import 'package:flutter/cupertino.dart';

const TextStyle textoPesquisa = TextStyle(
  color: Color.fromRGBO(0, 0, 0, 1),
  fontSize: 14,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.normal,
);
const Color fundoPesquisa = Color(0xffe0e0e0);
const Color cursorPesquisaCor = Color.fromRGBO(0, 122, 255, 1);
const Color iconePesquisaCor = Color.fromRGBO(128, 128, 128, 1);

class SearchBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  const SearchBar({
    Key? key,
    required this.textController,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundoPesquisa,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.search,
              color: iconePesquisaCor,
            ),
            Expanded(
              child: CupertinoTextField(
                controller: textController,
                focusNode: focusNode,
                style: textoPesquisa,
                cursorColor: cursorPesquisaCor,
              ),
            ),
            GestureDetector(
              onTap: () => textController.text = "",
              child: const Icon(
                CupertinoIcons.clear_thick_circled,
                color: iconePesquisaCor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
