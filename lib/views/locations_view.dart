import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/locations_controller.dart';

class LocationsView extends StatelessWidget {
  const LocationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationsController>();
    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.clearSearch();
            Get.back();
          },
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            controller.clearSearch();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade900,
              ),
              onChanged: (value) => controller.updateSearchQuery(value),
            ),
          ),

          // Results List
          Expanded(
            child: Obx(() {
              // Show search results when searching
              if (controller.searchQuery.isNotEmpty) {
                if (controller.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cities found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final location = controller.searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(location),
                      trailing: const Icon(Icons.add),
                      onTap: () {
                        controller.addLocationAndFetchWeather(location);
                        searchController.clear();
                        controller.clearSearch();
                        Get.back();
                      },
                    );
                  },
                );
              }

              // Show saved locations when not searching
              if (controller.locations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved locations',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for a city to add it',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.locations.length,
                itemBuilder: (context, index) {
                  final location = controller.locations[index];
                  return Dismissible(
                    key: Key(location),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      controller.deleteLocation(location);
                      Get.snackbar(
                        'Location Removed',
                        '$location has been removed',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(location),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => controller.deleteLocation(location),
                      ),
                      onTap: () {
                        controller.selectLocation(location);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
