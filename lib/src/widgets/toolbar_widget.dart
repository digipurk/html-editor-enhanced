import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:numberpicker/numberpicker.dart';

/// Toolbar widget class
class ToolbarWidget extends StatefulWidget {
  /// The [HtmlEditorController] is mainly used to call the [execCommand] method
  final HtmlEditorController controller;
  final HtmlEditorOptions options;

  const ToolbarWidget({
    Key? key,
    required this.controller,
    required this.options,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ToolbarWidgetState();
  }
}

/// Toolbar widget state
class ToolbarWidgetState extends State<ToolbarWidget> {
  /// List that controls which [ToggleButtons] are selected for
  /// bold/italic/underline/clear styles
  final fontSelected = List<bool>.filled(4, false);

  /// List that controls which [ToggleButtons] are selected for
  /// strikthrough/superscript/subscript
  final miscFontSelected = List<bool>.filled(3, false);

  /// List that controls which [ToggleButtons] are selected for
  /// forecolor/backcolor
  final colorSelected = List<bool>.filled(2, false);

  /// List that controls which [ToggleButtons] are selected for
  /// ordered/unordered list
  final paragraphSelected = List<bool>.filled(2, false);

  /// List that controls which [ToggleButtons] are selected for
  /// fullscreen, codeview, undo, redo, and help. Fullscreen and codeview
  /// are the only buttons that will ever be selected.
  final miscSelected = List<bool>.filled(5, false);

  /// List that controls which [ToggleButtons] are selected for
  /// justify left/right/center/full.
  List<bool> alignSelected = List<bool>.filled(4, false);

  /// Sets the selected item for the font style dropdown
  String fontSelectedItem = "p";

  /// Sets the selected item for the font size dropdown
  double fontSizeSelectedItem = 3;

  /// Keeps track of the current font size in px
  double actualFontSizeSelectedItem = 16;

  /// Sets the selected item for the font units dropdown
  String fontSizeUnitSelectedItem = "pt";

  /// Sets the selected item for the foreground color dialog
  Color foreColorSelected = Colors.black;

  /// Sets the selected item for the background color dialog
  Color backColorSelected = Colors.yellow;

  /// Sets the selected item for the list style dropdown
  String? listStyleSelectedItem;

  /// Sets the selected item for the line height dropdown
  double lineHeightSelectedItem = 1;

  @override
  void initState() {
    updateToolbar = _updateToolbar;
    super.initState();
  }

  /// Updates the toolbar from the JS handler on mobile and the onMessage
  /// listener on web
  void _updateToolbar(Map<String, dynamic> json) {
    //get parent element
    String parentElem = json['style'] ?? "";
    //get font size
    double fontSize = double.tryParse(json['fontSize']) ?? 3;
    //get bold/underline/italic status
    List<bool?> fontList = (json['font'] as List<dynamic>).cast<bool?>();
    //get superscript/subscript/strikethrough status
    List<bool?> miscFontList = (json['miscFont'] as List<dynamic>).cast<bool?>();
    //get forecolor/backcolor
    List<String?> colorList = (json['color'] as List<dynamic>).cast<String?>();
    //get ordered/unordered list status
    List<bool?> paragraphList = (json['paragraph'] as List<dynamic>).cast<bool?>();
    //get justify status
    List<bool?> alignList = (json['align'] as List<dynamic>).cast<bool?>();
    //get line height
    String lineHeight = json['lineHeight'] ?? "";
    //get list icon type
    String listType = json['listStyle'] ?? "";
    //check the parent element if it matches one of the predetermined styles and update the toolbar
    if (['pre', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'].contains(parentElem)) {
      setState(() {
        fontSelectedItem = parentElem;
      });
    } else {
      setState(() {
        fontSelectedItem = "p";
      });
    }
    //update the fore/back selected color if necessary
    if (colorList[0] != null && colorList[0]!.isNotEmpty) {
      setState(() {
        String rgb = colorList[0]!.replaceAll("rgb(", "").replaceAll(")", "");
        List<String> rgbList = rgb.split(", ");
        foreColorSelected = Color.fromRGBO(int.parse(rgbList[0]), int.parse(rgbList[1]), int.parse(rgbList[2]), 1);
      });
    } else {
      setState(() {
        foreColorSelected = Colors.black;
      });
    }
    if (colorList[1] != null && colorList[1]!.isNotEmpty) {
      setState(() {
        backColorSelected = Color(int.parse(colorList[1]!, radix: 16) + 0xFF000000);
      });
    } else {
      setState(() {
        backColorSelected = Colors.yellow;
      });
    }
    //check the list style if it matches one of the predetermined styles and update the toolbar
    if (['decimal', 'lower-alpha', 'upper-alpha', 'lower-roman', 'upper-roman', 'disc', 'circle', 'square'].contains(listType)) {
      setState(() {
        listStyleSelectedItem = listType;
      });
    } else {
      listStyleSelectedItem = null;
    }
    //update the lineheight selected item if necessary
    if (lineHeight.isNotEmpty && lineHeight.endsWith("px")) {
      double lineHeightDouble = double.tryParse(lineHeight.replaceAll("px", "")) ?? 16;
      List<double> lineHeights = [1, 1.2, 1.4, 1.5, 1.6, 1.8, 2, 3];
      lineHeights = lineHeights.map((e) => e * actualFontSizeSelectedItem).toList();
      if (lineHeights.contains(lineHeightDouble)) {
        setState(() {
          lineHeightSelectedItem = lineHeightDouble / actualFontSizeSelectedItem;
        });
      }
    } else if (lineHeight == "normal") {
      setState(() {
        lineHeightSelectedItem = 1.0;
      });
    }
    //check if the font size matches one of the predetermined sizes and update the toolbar
    if ([1, 2, 3, 4, 5, 6, 7].contains(fontSize)) {
      setState(() {
        fontSizeSelectedItem = fontSize;
      });
    }
    //use the remaining bool lists to update the selected items accordingly
    setState(() {
      fontSelected[0] = fontList[0] ?? false;
      fontSelected[1] = fontList[1] ?? false;
      fontSelected[2] = fontList[2] ?? false;
      miscFontSelected[0] = miscFontList[0] ?? false;
      miscFontSelected[1] = miscFontList[1] ?? false;
      miscFontSelected[2] = miscFontList[2] ?? false;
      paragraphSelected[0] = paragraphList[0] ?? false;
      paragraphSelected[1] = paragraphList[1] ?? false;
      alignSelected[0] = alignList[0] ?? false;
      alignSelected[1] = alignList[1] ?? false;
      alignSelected[2] = alignList[2] ?? false;
      alignSelected[3] = alignList[3] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      Container(
        padding: const EdgeInsets.only(left: 8.0),
        height: 36,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: ToggleButtonsTheme.of(context).borderColor ?? Colors.grey[800]!)
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            items: [
              DropdownMenuItem(child: Text("Normal"), value: "p"),
              DropdownMenuItem(child: Text("   Quote"), value: "blockquote"),
              DropdownMenuItem(child: Text("   Code", style: TextStyle(fontFamily: "times")), value: "pre"),
              DropdownMenuItem(child: Text("Header 1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)), value: "h1"),
              DropdownMenuItem(child: Text("Header 2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)), value: "h2"),
              DropdownMenuItem(child: Text("Header 3", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), value: "h3"),
              DropdownMenuItem(child: Text("Header 4", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), value: "h4"),
              DropdownMenuItem(child: Text("Header 5", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), value: "h5"),
              DropdownMenuItem(child: Text("Header 6", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), value: "h6"),
            ],
            value: fontSelectedItem,
            onChanged: (String? changed) {
              if (changed != null) {
                widget.controller.execCommand('formatBlock', argument: changed);
                setState(() {
                  fontSelectedItem = changed;
                });
              }
            },
          ),
        ),
      ),
      //todo font family??
      Container(
        padding: const EdgeInsets.only(left: 8.0),
        height: 36,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: ToggleButtonsTheme.of(context).borderColor ?? Colors.grey[800]!)
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            items: [
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "11" : "8"} $fontSizeUnitSelectedItem"),
                  value: 1
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "13" : "10"} $fontSizeUnitSelectedItem"),
                  value: 2
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "16" : "12"} $fontSizeUnitSelectedItem"),
                  value: 3
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "19" : "14"} $fontSizeUnitSelectedItem"),
                  value: 4
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "24" : "18"} $fontSizeUnitSelectedItem"),
                  value: 5
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "32" : "24"} $fontSizeUnitSelectedItem"),
                  value: 6
              ),
              DropdownMenuItem(
                  child: Text("${fontSizeUnitSelectedItem == "px" ? "48" : "36"} $fontSizeUnitSelectedItem"),
                  value: 7
              ),
            ],
            value: fontSizeSelectedItem,
            onChanged: (double? changed) {
              if (changed != null) {
                int intChanged = changed.toInt();
                switch (intChanged) {
                  case 1:
                    actualFontSizeSelectedItem = 11;
                    break;
                  case 2:
                    actualFontSizeSelectedItem = 13;
                    break;
                  case 3:
                    actualFontSizeSelectedItem = 16;
                    break;
                  case 4:
                    actualFontSizeSelectedItem = 19;
                    break;
                  case 5:
                    actualFontSizeSelectedItem = 24;
                    break;
                  case 6:
                    actualFontSizeSelectedItem = 32;
                    break;
                  case 7:
                    actualFontSizeSelectedItem = 48;
                    break;
                }
                widget.controller.execCommand('fontSize', argument: changed.toString());
                setState(() {
                  fontSizeSelectedItem = changed;
                });
              }
            },
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.only(left: 8.0),
        height: 36,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: ToggleButtonsTheme.of(context).borderColor ?? Colors.grey[800]!)
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            items: [
              DropdownMenuItem(child: Text("pt"), value: "pt"),
              DropdownMenuItem(child: Text("px"), value: "px"),
            ],
            value: fontSizeUnitSelectedItem,
            onChanged: (String? changed) {
              if (changed != null)
                setState(() {
                  fontSizeUnitSelectedItem = changed;
                });
            },
          ),
        ),
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_bold),
          Icon(Icons.format_italic),
          Icon(Icons.format_underlined),
          Icon(Icons.format_clear),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.execCommand('bold');
              break;
            case 1:
              widget.controller.execCommand('italic');
              break;
            case 2:
              widget.controller.execCommand('underline');
              break;
            case 3:
              widget.controller.execCommand('removeFormat');
              break;
          }
          if (index < 3) {
            setState(() {
              fontSelected[index] = !fontSelected[index];
            });
          }
        },
        isSelected: fontSelected,
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_strikethrough),
          Icon(Icons.superscript),
          Icon(Icons.subscript),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.execCommand('strikeThrough');
              break;
            case 1:
              widget.controller.execCommand('superscript');
              break;
            case 2:
              widget.controller.execCommand('subscript');
              break;
          }
          setState(() {
            miscFontSelected[index] = !miscFontSelected[index];
          });
        },
        isSelected: miscFontSelected,
      ),
      //todo needs a lot of testing
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_color_text, color: foreColorSelected),
          Icon(Icons.format_color_fill, color: backColorSelected),
        ],
        onPressed: (int index) {
          if (colorSelected[index]) {
            if (index == 0) {
              widget.controller.execCommand('foreColor',
                  argument: (Colors.black.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase());
            } else {
              widget.controller.execCommand('hiliteColor',
                  argument: (Colors.yellow.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase());
            }
            setState(() {
              colorSelected[index] = !colorSelected[index];
            });
          } else {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  late Color newColor;
                  if (index == 0)
                    newColor = foreColorSelected;
                  else
                    newColor = backColorSelected;
                  return AlertDialog(
                    title: Text('Pick ${index == 0 ? "text" : "highlight"} color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: newColor,
                        paletteType: PaletteType.hsv,
                        enableAlpha: false,
                        displayThumbColor: true,
                        onColorChanged: (Color changed) {
                          newColor = changed;
                        },
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      ),
                      TextButton(
                          onPressed: () {
                            if (index == 0) {
                              setState(() {
                                foreColorSelected = Colors.black;
                              });
                              widget.controller.execCommand('removeFormat', argument: 'foreColor');
                              widget.controller.execCommand('foreColor', argument: 'initial');
                            } else {
                              setState(() {
                                backColorSelected = Colors.yellow;
                              });
                              widget.controller.execCommand('removeFormat', argument: 'hiliteColor');
                              widget.controller.execCommand('hiliteColor', argument: 'initial');
                            }
                            Navigator.of(context).pop();
                          },
                          child: Text("Rest to default color")
                      ),
                      TextButton(
                        onPressed: () {
                          if (index == 0) {
                            widget.controller.execCommand('foreColor',
                                argument: (newColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase());
                            setState(() {
                              foreColorSelected = newColor;
                            });
                          } else {
                            widget.controller.execCommand('hiliteColor',
                                argument: (newColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase());
                            setState(() {
                              backColorSelected = newColor;
                            });
                          }
                          setState(() {
                            colorSelected[index] = !colorSelected[index];
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text("Set color"),
                      )
                    ],
                  );
                }
            );
          }
        },
        isSelected: colorSelected,
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_list_bulleted),
          Icon(Icons.format_list_numbered),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.execCommand('insertUnorderedList');
              break;
            case 1:
              widget.controller.execCommand('insertOrderedList');
              break;
          }
          setState(() {
            paragraphSelected[index] = !paragraphSelected[index];
          });
        },
        isSelected: paragraphSelected,
      ),
      Container(
        padding: const EdgeInsets.only(left: 8.0),
        height: 36,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: ToggleButtonsTheme.of(context).borderColor ?? Colors.grey[800]!)
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            items: [
              DropdownMenuItem(child: Text("1. Numbered"), value: "decimal"),
              DropdownMenuItem(child: Text("a. Lower Alpha"), value: "lower-alpha"),
              DropdownMenuItem(child: Text("A. Upper Alpha"), value: "upper-alpha"),
              DropdownMenuItem(child: Text("i. Lower Roman"), value: "lower-roman"),
              DropdownMenuItem(child: Text("I. Upper Roman"), value: "upper-roman"),
              DropdownMenuItem(child: Text("• Disc"), value: "disc"),
              DropdownMenuItem(child: Text("○ Circle"), value: "circle"),
              DropdownMenuItem(child: Text("■ Square"), value: "square"),
            ],
            hint: Text("Select list style"),
            value: listStyleSelectedItem,
            onChanged: (String? changed) {
              if (changed != null) {
                widget.controller.editorController!.evaluateJavascript(source: """
                               var \$focusNode = \$(window.getSelection().focusNode);
                               var \$parentList = \$focusNode.closest("div.note-editable ol, div.note-editable ul");
                               \$parentList.css("list-style-type", "$changed");
                            """);
                setState(() {
                  listStyleSelectedItem = changed;
                });
              }
            },
          ),
        ),
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_align_left),
          Icon(Icons.format_align_center),
          Icon(Icons.format_align_right),
          Icon(Icons.format_align_justify),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.execCommand('justifyLeft');
              break;
            case 1:
              widget.controller.execCommand('justifyCenter');
              break;
            case 2:
              widget.controller.execCommand('justifyRight');
              break;
            case 3:
              widget.controller.execCommand('justifyFull');
              break;
          }
          alignSelected = List<bool>.filled(4, false);
          setState(() {
            alignSelected[index] = !alignSelected[index];
          });
        },
        isSelected: alignSelected,
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.format_indent_increase),
          Icon(Icons.format_indent_decrease),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.execCommand('indent');
              break;
            case 1:
              widget.controller.execCommand('outdent');
              break;
          }
        },
        isSelected: [false, false],
      ),
      Container(
        height: 36,
        padding: const EdgeInsets.only(left: 8.0),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: ToggleButtonsTheme.of(context).borderColor ?? Colors.grey[800]!)
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            items: [
              DropdownMenuItem(child: Text("1.0"), value: 1),
              DropdownMenuItem(child: Text("1.2"), value: 1.2),
              DropdownMenuItem(child: Text("1.4"), value: 1.4),
              DropdownMenuItem(child: Text("1.5"), value: 1.5),
              DropdownMenuItem(child: Text("1.6"), value: 1.6),
              DropdownMenuItem(child: Text("1.8"), value: 1.8),
              DropdownMenuItem(child: Text("2.0"), value: 2),
              DropdownMenuItem(child: Text("3.0"), value: 3),
            ],
            value: lineHeightSelectedItem,
            onChanged: (double? changed) {
              if (changed != null) {
                widget.controller.editorController!.evaluateJavascript(source:"\$('#summernote-2').summernote('lineHeight', '$changed');");
                setState(() {
                  lineHeightSelectedItem = changed;
                });
              }
            },
          ),
        ),
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.link),
          Icon(Icons.image_outlined),
          Icon(Icons.videocam_outlined),
          Icon(Icons.table_chart_outlined),
          Icon(Icons.horizontal_rule),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              final TextEditingController text = TextEditingController();
              final TextEditingController url = TextEditingController();
              final FocusNode textFocus = FocusNode();
              final FocusNode urlFocus = FocusNode();
              final GlobalKey<FormState> formKey = GlobalKey<FormState>();
              bool openNewTab = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text("Insert Link"),
                            content: Form(
                              key: formKey,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Text to display", style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    TextField(
                                      controller: text,
                                      focusNode: textFocus,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: "Text",
                                      ),
                                      onSubmitted: (_) {
                                        urlFocus.requestFocus();
                                      },
                                    ),
                                    SizedBox(height: 20),
                                    Text("URL", style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: url,
                                      focusNode: urlFocus,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: "URL",
                                      ),
                                      validator: (String? value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please enter a URL!";
                                        }
                                        return null;
                                      },
                                    ),
                                    Row(
                                      children: <Widget>[
                                        SizedBox(
                                          height: 48.0,
                                          width: 24.0,
                                          child: Checkbox(
                                            value: openNewTab,
                                            activeColor: Color(0xFF827250),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                openNewTab = value!;
                                              });
                                            },
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              primary: Theme.of(context).dialogBackgroundColor,
                                              padding: EdgeInsets.only(left: 5, right: 5),
                                              elevation: 0.0
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              openNewTab = !openNewTab;
                                            });
                                          },
                                          child: Text("Open in new window"),
                                        ),
                                      ],
                                    ),
                                  ]
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    widget.controller.insertLink(
                                      text.text.isEmpty ? url.text : text.text,
                                      url.text,
                                      openNewTab,
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text("OK"),
                              )
                            ],
                          );
                        }
                    );
                  }
              );
              break;
            case 1:
              final TextEditingController filename = TextEditingController();
              final TextEditingController url = TextEditingController();
              final FocusNode urlFocus = FocusNode();
              FilePickerResult? result;
              String? validateFailed;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text("Insert Image"),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Select from files", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextFormField(
                                      controller: filename,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              primary: Theme.of(context).dialogBackgroundColor,
                                              padding: EdgeInsets.only(left: 5, right: 5),
                                              elevation: 0.0
                                          ),
                                          onPressed: () async {
                                            result = await FilePicker.platform.pickFiles(type: FileType.image);
                                            if (result?.files.single.name != null) {
                                              setState(() {
                                                filename.text = result!.files.single.name!;
                                              });
                                            }
                                          },
                                          child: Text("Choose image"),
                                        ),
                                        suffixIcon: result != null ?
                                        IconButton(
                                            icon: Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                result = null;
                                                filename.text = "";
                                              });
                                            }
                                        ) : Container(height: 0, width: 0),
                                        errorText: validateFailed,
                                        errorMaxLines: 2,
                                        border: InputBorder.none,
                                      )
                                  ),
                                  SizedBox(height: 20),
                                  Text("URL", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "URL",
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (filename.text.isEmpty && url.text.isEmpty) {
                                    setState(() {
                                      validateFailed = "Please either choose an image or enter an image URL!";
                                    });
                                  } else if (filename.text.isNotEmpty && url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed = "Please input either an image or an image URL, not both!";
                                    });
                                  } else if (filename.text.isNotEmpty && result?.files.single.path != null) {
                                    File file = File(result!.files.single.path!);
                                    Uint8List bytes = await file.readAsBytes();
                                    String base64Data = base64.encode(bytes);
                                    widget.controller.insertHtml(
                                        "<img src='data:image/${result!.files.single.extension};base64,$base64Data' data-filename='${result!.files.single.name}'/>");
                                    Navigator.of(context).pop();
                                  } else {
                                    widget.controller.insertNetworkImage(url.text);
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text("OK"),
                              )
                            ],
                          );
                        }
                    );
                  }
              );
              break;
            case 2:
              final TextEditingController filename = TextEditingController();
              final TextEditingController url = TextEditingController();
              final FocusNode urlFocus = FocusNode();
              FilePickerResult? result;
              String? validateFailed;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text("Insert Video"),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Select from files", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextFormField(
                                      controller: filename,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        prefixIcon: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              primary: Theme.of(context).dialogBackgroundColor,
                                              padding: EdgeInsets.only(left: 5, right: 5),
                                              elevation: 0.0
                                          ),
                                          onPressed: () async {
                                            result = await FilePicker.platform.pickFiles(type: FileType.video);
                                            if (result?.files.single.name != null) {
                                              setState(() {
                                                filename.text = result!.files.single.name!;
                                              });
                                            }
                                          },
                                          child: Text("Choose video"),
                                        ),
                                        suffixIcon: result != null ?
                                        IconButton(
                                            icon: Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                result = null;
                                                filename.text = "";
                                              });
                                            }
                                        ) : Container(height: 0, width: 0),
                                        errorText: validateFailed,
                                        errorMaxLines: 2,
                                        border: InputBorder.none,
                                      )
                                  ),
                                  SizedBox(height: 20),
                                  Text("URL", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: url,
                                    focusNode: urlFocus,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "URL",
                                      errorText: validateFailed,
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ]
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (filename.text.isEmpty && url.text.isEmpty) {
                                    setState(() {
                                      validateFailed = "Please either choose a video or enter a video URL!";
                                    });
                                  } else if (filename.text.isNotEmpty && url.text.isNotEmpty) {
                                    setState(() {
                                      validateFailed = "Please input either a video or a video URL, not both!";
                                    });
                                  } else if (filename.text.isNotEmpty && result?.files.single.path != null) {
                                    File file = File(result!.files.single.path!);
                                    Uint8List bytes = await file.readAsBytes();
                                    String base64Data = base64.encode(bytes);
                                    widget.controller.insertHtml(
                                        "<video src='data:video/${result!.files.single.extension};base64,$base64Data' data-filename='${result!.files.single.name}'></video>");
                                    Navigator.of(context).pop();
                                  } else {
                                    widget.controller.insertHtml("<video src='${url.text}'></video>");
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text("OK"),
                              )
                            ],
                          );
                        }
                    );
                  }
              );
              break;
            case 3:
              int currentRows = 1;
              int currentCols = 1;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text("Insert Table"),
                            content: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  NumberPicker(
                                    value: currentRows,
                                    minValue: 1,
                                    maxValue: 10,
                                    onChanged: (value) => setState(() => currentRows = value),
                                  ),
                                  Text('x'),
                                  NumberPicker(
                                    value: currentCols,
                                    minValue: 1,
                                    maxValue: 10,
                                    onChanged: (value) => setState(() => currentCols = value),
                                  ),
                                ]
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  widget.controller.editorController!.evaluateJavascript(source: "\$('#summernote-2').summernote('insertTable', '${currentRows}x$currentCols');");
                                  Navigator.of(context).pop();
                                },
                                child: Text("OK"),
                              )
                            ],
                          );
                        }
                    );
                  }
              );
              break;
            case 4:
              widget.controller.insertHtml("<hr/>");
              break;
          }
        },
        isSelected: [false, false, false, false, false],
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.fullscreen),
          Icon(Icons.code),
          Icon(Icons.undo),
          Icon(Icons.redo),
          Icon(Icons.help_outline),
        ],
        onPressed: (int index) {
          switch (index) {
            case 0:
              widget.controller.setFullScreen();
              break;
            case 1:
              widget.controller.toggleCodeView();
              break;
            case 2:
              widget.controller.undo();
              break;
            case 3:
              widget.controller.redo();
              break;
            case 4:
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text("Help"),
                            content: Container(
                              height: MediaQuery.of(context).size.height / 2,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 5,
                                  dataRowHeight: 75,
                                  columns: const <DataColumn>[
                                    DataColumn(
                                      label: Text(
                                        'Key Combination',
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Action',
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                  rows: const <DataRow>[
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('ESC')),
                                        DataCell(Text('Escape')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('ENTER')),
                                        DataCell(Text('Insert Paragraph')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+Z')),
                                        DataCell(Text('Undo the last command')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+Z')),
                                        DataCell(Text('Undo the last command')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+Y')),
                                        DataCell(Text('Redo the last command')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('TAB')),
                                        DataCell(Text('Tab')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('SHIFT+TAB')),
                                        DataCell(Text('Untab')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+B')),
                                        DataCell(Text('Set a bold style')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+I')),
                                        DataCell(Text('Set an italic style')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+U')),
                                        DataCell(Text('Set an underline style')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+S')),
                                        DataCell(Text('Set a strikethrough style')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+BACKSLASH')),
                                        DataCell(Text('Clean a style')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+L')),
                                        DataCell(Text('Set left align')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+E')),
                                        DataCell(Text('Set center align')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+R')),
                                        DataCell(Text('Set right align')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+J')),
                                        DataCell(Text('Set full align')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+NUM7')),
                                        DataCell(Text('Toggle unordered list')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+SHIFT+NUM8')),
                                        DataCell(Text('Toggle ordered list')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+LEFTBRACKET')),
                                        DataCell(Text('Outdent on current paragraph')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+RIGHTBRACKET')),
                                        DataCell(Text('Indent on current paragraph')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM0')),
                                        DataCell(Text('Change current block\'s format as a paragraph (<p> tag)')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM1')),
                                        DataCell(Text('Change current block\'s format as H1')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM2')),
                                        DataCell(Text('Change current block\'s format as H2')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM3')),
                                        DataCell(Text('Change current block\'s format as H3')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM4')),
                                        DataCell(Text('Change current block\'s format as H4')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM5')),
                                        DataCell(Text('Change current block\'s format as H5')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+NUM6')),
                                        DataCell(Text('Change current block\'s format as H6')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+ENTER')),
                                        DataCell(Text('Insert horizontal rule')),
                                      ],
                                    ),
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text('CTRL+K')),
                                        DataCell(Text('Show link dialog')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Close"),
                              )
                            ],
                          );
                        }
                    );
                  }
              );
              break;
          }
          if (index < 2) {
            setState(() {
              miscSelected[index] = !miscSelected[index];
            });
          }
        },
        isSelected: miscSelected,
      ),
      ToggleButtons(
        constraints: BoxConstraints(
          minHeight: 34,
          maxHeight: 34,
          minWidth: 34,
          maxWidth: 34,
        ),
        children: [
          Icon(Icons.copy),
          Icon(Icons.paste),
        ],
        onPressed: (int index) async {
          switch (index) {
            case 0:
              String? data = await widget.controller.getText();
              Clipboard.setData(new ClipboardData(text: data));
              break;
            case 1:
              ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null) {
                String text = data.text!;
                widget.controller.insertHtml(text);
              }
              break;
          }
        },
        isSelected: [false, false],
      ),
    ];
    if (widget.options.toolbarType == ToolbarType.nativeGrid) {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Wrap(
          runSpacing: 5,
          spacing: 5,
          children: children,
        ),
      );
    } else {
      return Container(
        height: 39,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: CustomScrollView(
            scrollDirection: Axis.horizontal,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
