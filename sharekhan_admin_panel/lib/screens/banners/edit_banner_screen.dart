import 'dart:typed_data';
import 'package:sharekhan_admin_panel/globals.dart';
import 'package:sharekhan_admin_panel/navigation/go_router.dart';
import 'package:sharekhan_admin_panel/navigation/routes.dart';
import 'package:sharekhan_admin_panel/providers/product_provider.dart';
import 'package:sharekhan_admin_panel/widgets/common/custom_loading.dart';
import 'package:sharekhan_admin_panel/widgets/common/edit_tab_footer.dart';
import 'package:sharekhan_admin_panel/widgets/common/secondary_tab_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:sharekhan_admin_panel/models/banner_model.dart';
import 'package:sharekhan_admin_panel/providers/banner_provider.dart';
import 'package:sharekhan_admin_panel/theme/app_theme.dart';
import 'package:sharekhan_admin_panel/widgets/common/custom_button.dart';
import 'package:sharekhan_admin_panel/widgets/common/custom_dropdown.dart';
import 'package:sharekhan_admin_panel/widgets/common/spacing.dart';

class EditBannerScreen extends StatefulWidget {
  final BannerModel banner;
  const EditBannerScreen({super.key, required this.banner});

  @override
  State<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends State<EditBannerScreen> {
  String _fileName = 'File Name';
  String _productID = '';
  List<String> _products = [];
  Uint8List? _imageData;
  String? _imageUrl;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final MediaInfo? pickedFile = await ImagePickerWeb.getImageInfo();
    if (pickedFile != null) {
      setState(() {
        _imageData = pickedFile.data;
        _fileName = pickedFile.fileName!;
      });
    }
  }

  Future<String> _uploadImage(Uint8List imageData, String bannerID) async {
    final storageRef = firebaseStorage.ref();
    final imagesRef = storageRef.child('banners/$bannerID.png');
    await imagesRef.putData(imageData);
    final imageUrl = await imagesRef.getDownloadURL();
    return imageUrl;
  }

  _editBanner() async {
    setState(() {
      _isLoading = true;
    });
    final bannerProvider = context.read<BannerProvider>();
    if (_imageData != null) {
      _imageUrl = await _uploadImage(_imageData!, widget.banner.id);
    }

    BannerModel banner = BannerModel(
      createdAt: widget.banner.createdAt,
      updatedAt: DateTime.now(),
      description: _descriptionController.text.trim(),
      id: widget.banner.id,
      productID: _productID,
      isActive: true,
      imageUrl: _imageUrl ?? '',
    );
    await bannerProvider.updateBanner(banner);
    setState(() {
      _isLoading = false;
    });
    router.go(Routes.banners);
  }

  init() {
    final productProvider = context.read<ProductProvider>();
    setState(() {
      _fileName = widget.banner.imageUrl;
      _descriptionController.text = widget.banner.description;
      _productID = widget.banner.productID;
      _imageUrl = widget.banner.imageUrl;
      _products = productProvider.products.map((e) => e.name).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    return !_isLoading
        ? Scaffold(
            backgroundColor: AppTheme.colorWhite,
            body: Padding(
              padding: AppTheme.paddingSmall,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Spacing(size: AppTheme.spacingLarge),
                      const BreadcrumbTabHeader(
                        goBackRoute: Routes.banners,
                        mainTitle: 'Banners',
                        secondaryTitle: 'Edit Banner',
                      ),
                      const Spacing(size: AppTheme.spacingSmall),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image*',
                                style: AppTheme.fontStyleDefault
                                    .copyWith(color: AppTheme.colorGrey),
                              ),
                              const Spacing(size: AppTheme.spacingTiny),
                              Row(
                                children: [
                                  Container(
                                    height: 40,
                                    width: 200,
                                    padding: AppTheme.paddingTiny,
                                    decoration: AppTheme.cardDecoration,
                                    child: Text(
                                      _fileName,
                                      style: AppTheme.fontStyleSmall
                                          .copyWith(color: AppTheme.colorGrey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Spacing(
                                      size: AppTheme.spacingTiny,
                                      isHorizontal: true),
                                  CustomButton(
                                    onTap: _pickImage,
                                    text: 'Upload Image',
                                    fillColor: AppTheme.colorRed,
                                    textColor: AppTheme.colorWhite,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacing(
                              size: AppTheme.spacingMedium, isHorizontal: true),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product*',
                                style: AppTheme.fontStyleDefault
                                    .copyWith(color: AppTheme.colorGrey),
                              ),
                              const Spacing(size: AppTheme.spacingTiny),
                              SizedBox(
                                width: 300,
                                child: CustomDropdown(
                                  value: productProvider.products
                                      .firstWhere(
                                          (element) => element.id == _productID)
                                      .name,
                                  hintText: 'Choose an option',
                                  items: _products
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _productID = productProvider.products
                                          .firstWhere(
                                              (element) => element.name == val)
                                          .id;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacing(size: AppTheme.spacingMedium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description*',
                            style: AppTheme.fontStyleDefault
                                .copyWith(color: AppTheme.colorGrey),
                          ),
                          const Spacing(size: AppTheme.spacingTiny),
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Enter the banner description here',
                              hintStyle: AppTheme.fontStyleDefault.copyWith(
                                color: AppTheme.greyTextColor,
                              ),
                              border: AppTheme.textfieldBorder,
                              enabledBorder: AppTheme.textfieldBorder,
                              focusedBorder: AppTheme.textfieldBorder,
                              filled: true,
                              fillColor: AppTheme.colorWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  EditTabFooter(
                    goBackrouteName: Routes.banners,
                    onSave: _editBanner,
                  ),
                ],
              ),
            ),
          )
        : const CustomLoading();
  }
}
