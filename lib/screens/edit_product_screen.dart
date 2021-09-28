import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/product.dart';
import 'package:shop_app/providers/products.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = "/edit-product";

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  TextEditingController _imageUrlController = TextEditingController(
    text: "",
  );
  final _imageUrlFocusNode = FocusNode();
  final _form = GlobalKey<FormState>();
  var _isInited = true;
  // var _initValues = {
  //   "title": "",
  //   "description": "",
  //   "price": "",
  //   "imageUrl": "",
  // };

  var _edittingTitle = "",
      _edittingDescription = "",
      _edittingPrice = 0.0,
      _edittingImageUrl = "";
  String? _edittingId;
  late bool _currentFavoriteState;
  bool _isLoading = false;

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  //is called whenever the object it's relying on change

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInited) {
      String? productId = ModalRoute.of(context)?.settings.arguments as String?;
      if (productId != null) {
        final product =
            Provider.of<Products>(context, listen: false).findById(productId);
        _edittingTitle = product.title;
        _edittingDescription = product.description;
        _edittingPrice = product.price;
        _imageUrlController.text = product.imageUrl;
        /* _initValues = {
        "title": _edittingTitle,
        "description": _edittingDescription,
        "price": _edittingPrice.toString(),
        "imageUrl": _edittingImageUrl,
        }; */
        _edittingId = product.id;
        _currentFavoriteState = product.isFavorite;
      }
    }
    _isInited = false;
  }

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      //validate then return.
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    if (_edittingId != null) {
      await Provider.of<Products>(context, listen: false).updateProduct(
          _edittingId!,
          Product(
              id: _edittingId!,
              title: _edittingTitle,
              description: _edittingDescription,
              price: _edittingPrice,
              imageUrl: _edittingImageUrl,
              isFavorite: _currentFavoriteState));
    } else {
      try {
        await Provider.of<Products>(context, listen: false).addProduct(Product(
            id: "",
            title: _edittingTitle,
            description: _edittingDescription,
            price: _edittingPrice,
            imageUrl: _edittingImageUrl));
      } catch (error) {
        await showDialog<Null>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Error occured"),
            content: Text("There're something wrong"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text("Okay")),
            ],
          ),
        );
      }
      // finally {
      //   setState(() {
      //     _isLoading = false;
      //   });
      //   Navigator.of(context).pop();
      // }
    }
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Product"),
        actions: [
          IconButton(
            onPressed: () {
              _saveForm();
            },
            icon: Icon(Icons.save),
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _edittingTitle,
                      decoration: InputDecoration(
                        labelText: "Title",
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (val) {
                        assert(val!.isNotEmpty);
                        if (val!.isEmpty) {
                          return "Please provide a value";
                        }
                        return null;
                      },
                      onSaved: (val) {
                        assert(val!.isNotEmpty);
                        _edittingTitle = val!;
                      },
                    ),
                    TextFormField(
                      initialValue: _edittingPrice == 0.0
                          ? " "
                          : _edittingPrice.toString(),
                      // _edittingPrice == 0.0 ? "" : ,
                      decoration: InputDecoration(labelText: "Price"),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode);
                      },
                      validator: (val) {
                        if (val!.isEmpty) {
                          return "Please enter a price";
                        }
                        if (double.tryParse(val) == null) {
                          return "Please enter valid number";
                        }
                        if (double.parse(val) <= 0) {
                          return "Please enter a number greater than zero";
                        }
                        return null;
                      },
                      onSaved: (val) {
                        _edittingPrice = double.tryParse(val!)!;
                      },
                    ),
                    TextFormField(
                      initialValue: _edittingDescription,
                      decoration: InputDecoration(labelText: "Description"),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                      validator: (val) {
                        if (val!.isEmpty) {
                          return "Please enter a description";
                        }
                        if (val.length < 10) {
                          return "Should be at least 10 characters long";
                        }
                        return null;
                      },
                      onSaved: (val) {
                        _edittingDescription = val!;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(top: 8, right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: _imageUrlController.text.isEmpty
                              ? Text("Enter an URL")
                              : FittedBox(
                                  child: Image.network(
                                    _imageUrlController.text,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: "Image URL"),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            controller: _imageUrlController,
                            focusNode: _imageUrlFocusNode,
                            onEditingComplete: () {
                              setState(() {});
                            },
                            onFieldSubmitted: (_) {
                              _saveForm();
                            },
                            validator: (val) {
                              if (val!.isEmpty) {
                                return "Please enter an URL";
                              }
                              if (!val.startsWith("http") &&
                                  !val.startsWith("https")) {
                                return "Please enter a valid URL";
                              }
                              return null;
                            },
                            onSaved: (val) {
                              _edittingImageUrl = val!;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
