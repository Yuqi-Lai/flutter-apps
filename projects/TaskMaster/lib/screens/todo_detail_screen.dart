import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/todo_item.dart';
import '../services/location_service.dart';

class TodoDetailScreen extends StatefulWidget {
  final TodoItem todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String? _distanceText;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    if (!widget.todo.hasLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _calculateDistance();
        });
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _calculateDistance() {
    if (_currentPosition != null && widget.todo.hasLocation) {
      final distance = LocationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.todo.latitude!,
        widget.todo.longitude!,
      );
      setState(() {
        _distanceText = LocationService.formatDistance(distance);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Details'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.todo.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: widget.todo.isCompleted
                            ? Colors.green
                            : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.todo.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: widget.todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${DateFormat('MMMM dd, yyyy').format(widget.todo.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
            ),

            if (widget.todo.dueDate != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: widget.todo.isOverdue
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due Date',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.todo.isOverdue
                            ? Colors.red[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.todo.isOverdue
                              ? Colors.red[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: widget.todo.isOverdue
                                ? Colors.red[700]
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(widget.todo.dueDate!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: widget.todo.isOverdue
                                  ? Colors.red[700]
                                  : Colors.black,
                            ),
                          ),
                          if (widget.todo.isOverdue) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.todo.imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Image',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.todo.imageUrl!.startsWith('/')
                          ? Image.file(
                              File(widget.todo.imageUrl!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
                            )
                          : Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50),
                            ),
                    ),
                  ],
                ),
              ),

            if (widget.todo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.todo.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),

            if (widget.todo.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.todo.address,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.todo.hasLocation)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      if (_isLoadingLocation)
                        const CircularProgressIndicator()
                      else if (_distanceText != null)
                        Text(
                          'Approximate distance: $_distanceText',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      else
                        const Text('Getting your location...'),
                    ],
                  ),
                ),
              ),

            if (widget.todo.hasLocation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map View',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.todo.latitude!,
                            widget.todo.longitude!,
                          ),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('todo_location'),
                            position: LatLng(
                              widget.todo.latitude!,
                              widget.todo.longitude!,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.todo.title,
                              snippet: widget.todo.address,
                            ),
                          ),
                          if (_currentPosition != null)
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Your Location',
                              ),
                            ),
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_currentPosition != null) {
                            _fitBounds();
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapToolbarEnabled: true,
                        zoomControlsEnabled: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

            if (!widget.todo.hasLocation)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No location set for this task',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fitBounds() {
    if (_mapController != null &&
        _currentPosition != null &&
        widget.todo.hasLocation) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < widget.todo.latitude!
              ? _currentPosition!.latitude
              : widget.todo.latitude!,
          _currentPosition!.longitude < widget.todo.longitude!
              ? _currentPosition!.longitude
              : widget.todo.longitude!,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > widget.todo.latitude!
              ? _currentPosition!.latitude
              : widget.todo.latitude!,
          _currentPosition!.longitude > widget.todo.longitude!
              ? _currentPosition!.longitude
              : widget.todo.longitude!,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

