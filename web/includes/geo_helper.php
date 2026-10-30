<?php
/**
 * Bangladesh Administrative Divisions, Districts, and Upazillas
 * Coordinate boundaries and Centroid Mapping for Pothole Density Analysis
 */

class BangladeshGeo {

    /**
     * Complete Hierarchy of Bangladesh: Divisions -> Districts -> Upazillas
     */
    public static function getHierarchy(): array {
        return [
            'Khulna' => [
                'Khulna' => [
                    'Khan Jahan Ali', 'Khulna Sadar', 'Phultala', 'Dighalia', 'Khalishpur',
                    'Daulatpur', 'Sonadanga', 'Dumuria', 'Batiaghata', 'Dacope',
                    'Paikgachha', 'Koyra', 'Rupsha', 'Terokhada'
                ],
                'Kushtia' => [
                    'Kushtia Sadar', 'Kumarkhali', 'Khoksa', 'Mirpur', 'Bheramara', 'Daulatpur'
                ],
                'Jashore' => [
                    'Jashore Sadar', 'Jhikargachha', 'Sharsha', 'Bagherpara', 'Abhaynagar',
                    'Manirampur', 'Keshabpur', 'Chaugachha'
                ],
                'Jhenaidah' => [
                    'Jhenaidah Sadar', 'Kaliganj', 'Kotchandpur', 'Maheshpur', 'Shailkupa', 'Harinakundu'
                ],
                'Bagerhat' => [
                    'Bagerhat Sadar', 'Fakirhat', 'Mollahat', 'Kachua', 'Rampal',
                    'Mongla', 'Morrelganj', 'Sarankhola', 'Chitalmari'
                ],
                'Satkhira' => [
                    'Satkhira Sadar', 'Kalaroa', 'Tala', 'Debhata', 'Kaliganj', 'Assasuni', 'Shyamnagar'
                ],
                'Chuadanga' => [
                    'Chuadanga Sadar', 'Alamdanga', 'Damurhuda', 'Jibannagar'
                ],
                'Magura' => [
                    'Magura Sadar', 'Sreepur', 'Mohammadpur', 'Shalikha'
                ],
                'Meherpur' => [
                    'Meherpur Sadar', 'Gangni', 'Mujibnagar'
                ],
                'Narail' => [
                    'Narail Sadar', 'Lohagara', 'Kalia'
                ]
            ],
            'Dhaka' => [
                'Dhaka' => [
                    'Mirpur', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Uttara',
                    'Savar', 'Keraniganj', 'Dhamrai', 'Tejgaon', 'Ramna',
                    'Motijheel', 'Khilgaon', 'Badda', 'Pallabi', 'Kafrul', 'Shah Ali'
                ],
                'Gazipur' => [
                    'Gazipur Sadar', 'Kaliakair', 'Kaliganj', 'Kapasia', 'Sreepur', 'Tongi'
                ],
                'Narayanganj' => [
                    'Narayanganj Sadar', 'Bandar', 'Rupganj', 'Sonargaon', 'Araihazar'
                ],
                'Tangail' => [
                    'Tangail Sadar', 'Gopalpur', 'Ghatail', 'Madhupur', 'Mirzapur', 'Sakhipur', 'Kalihati', 'Basail'
                ],
                'Faridpur' => [
                    'Faridpur Sadar', 'Boalmari', 'Alfadanga', 'Madhukhali', 'Bhanga', 'Nagarkanda', 'Charbhadrasan', 'Sadarpur'
                ],
                'Manikganj' => [
                    'Manikganj Sadar', 'Singair', 'Shibalaya', 'Saturia', 'Harirampur', 'Ghior', 'Daulatpur'
                ],
                'Munshiganj' => [
                    'Munshiganj Sadar', 'Sreenagar', 'Sirajdikhan', 'Louhajang', 'Tongibari', 'Gazaria'
                ],
                'Narsingdi' => [
                    'Narsingdi Sadar', 'Palash', 'Belabo', 'Monohardi', 'Shibpur', 'Raipura'
                ],
                'Rajbari' => [
                    'Rajbari Sadar', 'Goalanda', 'Pangsha', 'Baliakandi', 'Kalukhali'
                ],
                'Madaripur' => [
                    'Madaripur Sadar', 'Shibchar', 'Kalkini', 'Rajoir'
                ],
                'Gopalganj' => [
                    'Gopalganj Sadar', 'Kashiani', 'Kotalipara', 'Muksudpur', 'Tungipara'
                ],
                'Shariatpur' => [
                    'Shariatpur Sadar', 'Zajira', 'Naria', 'Bhedarganj', 'Damudya', 'Gosairhat'
                ]
            ],
            'Chattogram' => [
                'Chattogram' => [
                    'Kotwali', 'Panchlaish', 'Pahartali', 'Halishahar', 'Patenga', 'Hathazari',
                    'Sitakunda', 'Mirsharai', 'Patiya', 'Boalkhali', 'Anwara', 'Chandanaish',
                    'Satkania', 'Lohagara', 'Banshkhali', 'Raozan', 'Rangunia'
                ],
                'Cox\'s Bazar' => [
                    'Cox\'s Bazar Sadar', 'Chakaria', 'Maheshkhali', 'Teknaf', 'Ukhia', 'Ramu', 'Pekua', 'Kutubdia'
                ],
                'Cumilla' => [
                    'Cumilla Sadar', 'Debidwar', 'Muradnagar', 'Daudkandi', 'Chandina', 'Laksam',
                    'Brahmanpara', 'Burichang', 'Chauddagram', 'Barura', 'Homna', 'Titas'
                ],
                'Feni' => ['Feni Sadar', 'Daganbhuiyan', 'Chhagalnaiya', 'Sonagazi', 'Parshuram', 'Fulgazi'],
                'Brahmanbaria' => ['Brahmanbaria Sadar', 'Ashuganj', 'Sarail', 'Nasirnagar', 'Nabinagar', 'Bancharampur', 'Kasba', 'Akhaura'],
                'Noakhali' => ['Noakhali Sadar', 'Begumganj', 'Chatkhil', 'Companiganj', 'Hatiya', 'Senbagh', 'Sonaimuri', 'Subarnachar'],
                'Lakshmipur' => ['Lakshmipur Sadar', 'Raipur', 'Ramganj', 'Ramgati', 'Kamalnagar'],
                'Chandpur' => ['Chandpur Sadar', 'Faridganj', 'Haimchar', 'Haziganj', 'Kachua', 'Matlab Dakshin', 'Matlab Uttar', 'Shahrasti']
            ],
            'Rajshahi' => [
                'Rajshahi' => [
                    'Boalia', 'Motihar', 'Rajputra', 'Shah Makhdum', 'Paba', 'Durgapur',
                    'Bagmara', 'Charghat', 'Puthia', 'Bagha', 'Godagari', 'Tanore', 'Mohanpur'
                ],
                'Bogura' => [
                    'Bogura Sadar', 'Shibganj', 'Sonatola', 'Gabtali', 'Sariakandi', 'Dhunat',
                    'Sherpur', 'Nandigram', 'Kahaloo', 'Adamdighi', 'Dupchanchia', 'Shajahanpur'
                ],
                'Pabna' => ['Pabna Sadar', 'Ishwardi', 'Chatmohar', 'Sujanagar', 'Santhia', 'Bera', 'Bhangoora', 'Faridpur', 'Atgharia'],
                'Sirajganj' => ['Sirajganj Sadar', 'Belkuchi', 'Chauhali', 'Kamarkhanda', 'Kazipur', 'Raiganj', 'Shahjadpur', 'Tarash', 'Ullahpara'],
                'Natore' => ['Natore Sadar', 'Baraigram', 'Gurudaspur', 'Lalpur', 'Singra', 'Bagatipara', 'Naldanga'],
                'Naogaon' => ['Naogaon Sadar', 'Badalgachhi', 'Dhamoirhat', 'Manda', 'Mohadevpur', 'Niamatpur', 'Patnitala', 'Porsha', 'Raninagar', 'Sapahar', 'Atrai']
            ],
            'Barishal' => [
                'Barishal' => [
                    'Barishal Sadar', 'Babuganj', 'Bakerganj', 'Banaripara', 'Gaurnadi',
                    'Agailjhara', 'Mehendiganj', 'Muladi', 'Hizla', 'Wazirpur'
                ],
                'Bhola' => ['Bhola Sadar', 'Burhanuddin', 'Char Fasson', 'Daulatkhan', 'Lalmohan', 'Manpura', 'Tazumuddin'],
                'Patuakhali' => ['Patuakhali Sadar', 'Bauphal', 'Dashmina', 'Galachipa', 'Kalapara', 'Mirzaganj', 'Dumki', 'Rangabali'],
                'Pirojpur' => ['Pirojpur Sadar', 'Bhandaria', 'Kawkhali', 'Mathbaria', 'Nazirpur', 'Nesarabad', 'Zianagar'],
                'Jhalokathi' => ['Jhalokathi Sadar', 'Kathalia', 'Nalchity', 'Rajapur'],
                'Barguna' => ['Barguna Sadar', 'Amtali', 'Bamna', 'Betagi', 'Patharghata', 'Taltali']
            ],
            'Sylhet' => [
                'Sylhet' => [
                    'Sylhet Sadar', 'Beanibazar', 'Golapganj', 'Companiganj', 'Fenchuganj',
                    'Balaganj', 'Biswanath', 'Gowainghat', 'Jaintiapur', 'Zakiganj', 'Kanaighat', 'Dakshin Surma'
                ],
                'Moulvibazar' => ['Moulvibazar Sadar', 'Barlekha', 'Juri', 'Kamalganj', 'Kulaura', 'Rajnagar', 'Sreemangal'],
                'Habiganj' => ['Habiganj Sadar', 'Bahubal', 'Baniachong', 'Chunarughat', 'Lakhai', 'Madhabpur', 'Nabiganj', 'Ajmiriganj'],
                'Sunamganj' => ['Sunamganj Sadar', 'Bishwamvarpur', 'Chhatak', 'Derai', 'Dharampasha', 'Dowarabazar', 'Jagannathpur', 'Jamalganj', 'Sullah', 'Tahirpur']
            ],
            'Rangpur' => [
                'Rangpur' => [
                    'Rangpur Sadar', 'Badarganj', 'Gangachhara', 'Kaunia', 'Mithapukur', 'Pirgachha', 'Pirganj', 'Taraganj'
                ],
                'Dinajpur' => ['Dinajpur Sadar', 'Birampur', 'Birganj', 'Biral', 'Bochaganj', 'Chirirbandar', 'Phulbari', 'Ghoraghat', 'Hakimpur', 'Kaharole', 'Khansama', 'Nawabganj', 'Parbatipur'],
                'Gaibandha' => ['Gaibandha Sadar', 'Fulchhari', 'Gobindaganj', 'Palashbari', 'Sadullapur', 'Saghata', 'Sundarganj']
            ],
            'Mymensingh' => [
                'Mymensingh' => [
                    'Mymensingh Sadar', 'Muktagachha', 'Fulbaria', 'Trishal', 'Bhaluka',
                    'Gafargaon', 'Nandail', 'Ishwarganj', 'Haluaghat', 'Dhobaura', 'Phulpur', 'Tara Khanda'
                ],
                'Jamalpur' => ['Jamalpur Sadar', 'Baksiganj', 'Dewanganj', 'Islampur', 'Madarganj', 'Melandaha', 'Sarishabari'],
                'Netrokona' => ['Netrokona Sadar', 'Atpara', 'Barhatta', 'Durgapur', 'Khaliajuri', 'Kalmakanda', 'Kendua', 'Madan', 'Mohanganj', 'Purbadhala'],
                'Sherpur' => ['Sherpur Sadar', 'Jhenaigati', 'Nakla', 'Nalitabari', 'Sreebardi']
            ]
        ];
    }

    /**
     * Known geographic centroids & bounds for key Upazillas across Bangladesh
     */
    public static function getCentroids(): array {
        return [
            // Khulna Division - Khulna District
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Khan Jahan Ali', 'lat' => 22.8985, 'lng' => 89.5003, 'radius' => 0.035],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Phultala', 'lat' => 22.9785, 'lng' => 89.4600, 'radius' => 0.05],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Daulatpur', 'lat' => 22.8685, 'lng' => 89.5200, 'radius' => 0.03],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Khalishpur', 'lat' => 22.8500, 'lng' => 89.5350, 'radius' => 0.025],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Sonadanga', 'lat' => 22.8250, 'lng' => 89.5400, 'radius' => 0.03],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Khulna Sadar', 'lat' => 22.8100, 'lng' => 89.5600, 'radius' => 0.04],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Dighalia', 'lat' => 22.9100, 'lng' => 89.5350, 'radius' => 0.04],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Dumuria', 'lat' => 22.8050, 'lng' => 89.4200, 'radius' => 0.06],
            ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Rupsha', 'lat' => 22.8200, 'lng' => 89.5850, 'radius' => 0.04],

            // Khulna Division - Kushtia District
            ['division' => 'Khulna', 'district' => 'Kushtia', 'upazilla' => 'Kushtia Sadar', 'lat' => 23.9085, 'lng' => 89.1241, 'radius' => 0.06],
            ['division' => 'Khulna', 'district' => 'Kushtia', 'upazilla' => 'Kumarkhali', 'lat' => 23.8600, 'lng' => 89.2450, 'radius' => 0.06],
            ['division' => 'Khulna', 'district' => 'Kushtia', 'upazilla' => 'Bheramara', 'lat' => 24.0200, 'lng' => 88.9950, 'radius' => 0.06],
            ['division' => 'Khulna', 'district' => 'Kushtia', 'upazilla' => 'Mirpur', 'lat' => 23.9300, 'lng' => 88.9850, 'radius' => 0.06],

            // Khulna Division - Jashore
            ['division' => 'Khulna', 'district' => 'Jashore', 'upazilla' => 'Jashore Sadar', 'lat' => 23.1667, 'lng' => 89.2167, 'radius' => 0.07],
            ['division' => 'Khulna', 'district' => 'Jashore', 'upazilla' => 'Abhaynagar', 'lat' => 23.0100, 'lng' => 89.4400, 'radius' => 0.05],

            // Dhaka Division - Dhaka District
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Mirpur', 'lat' => 23.8103, 'lng' => 90.3667, 'radius' => 0.04],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Gulshan', 'lat' => 23.7925, 'lng' => 90.4078, 'radius' => 0.035],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Dhanmondi', 'lat' => 23.7465, 'lng' => 90.3760, 'radius' => 0.03],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Uttara', 'lat' => 23.8759, 'lng' => 90.3795, 'radius' => 0.04],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Mohammadpur', 'lat' => 23.7658, 'lng' => 90.3584, 'radius' => 0.03],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Savar', 'lat' => 23.8583, 'lng' => 90.2667, 'radius' => 0.07],
            ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Keraniganj', 'lat' => 23.6800, 'lng' => 90.3100, 'radius' => 0.06],

            // Chattogram Division
            ['division' => 'Chattogram', 'district' => 'Chattogram', 'upazilla' => 'Kotwali', 'lat' => 22.3419, 'lng' => 91.8340, 'radius' => 0.04],
            ['division' => 'Chattogram', 'district' => 'Chattogram', 'upazilla' => 'Panchlaish', 'lat' => 22.3683, 'lng' => 91.8256, 'radius' => 0.04],
            ['division' => 'Chattogram', 'district' => 'Cox\'s Bazar', 'upazilla' => 'Cox\'s Bazar Sadar', 'lat' => 21.4272, 'lng' => 92.0058, 'radius' => 0.07],

            // Rajshahi Division
            ['division' => 'Rajshahi', 'district' => 'Rajshahi', 'upazilla' => 'Boalia', 'lat' => 24.3636, 'lng' => 88.6241, 'radius' => 0.04],
            ['division' => 'Rajshahi', 'district' => 'Rajshahi', 'upazilla' => 'Motihar', 'lat' => 24.3700, 'lng' => 88.6400, 'radius' => 0.04],
            ['division' => 'Rajshahi', 'district' => 'Bogura', 'upazilla' => 'Bogura Sadar', 'lat' => 24.8465, 'lng' => 89.3777, 'radius' => 0.06],

            // Barishal Division
            ['division' => 'Barishal', 'district' => 'Barishal', 'upazilla' => 'Barishal Sadar', 'lat' => 22.7010, 'lng' => 90.3535, 'radius' => 0.06],

            // Sylhet Division
            ['division' => 'Sylhet', 'district' => 'Sylhet', 'upazilla' => 'Sylhet Sadar', 'lat' => 24.8949, 'lng' => 91.8687, 'radius' => 0.06],

            // Rangpur Division
            ['division' => 'Rangpur', 'district' => 'Rangpur', 'upazilla' => 'Rangpur Sadar', 'lat' => 25.7439, 'lng' => 89.2752, 'radius' => 0.06],

            // Mymensingh Division
            ['division' => 'Mymensingh', 'district' => 'Mymensingh', 'upazilla' => 'Mymensingh Sadar', 'lat' => 24.7471, 'lng' => 90.4203, 'radius' => 0.06]
        ];
    }

    /**
     * Resolves Division, District, and Upazilla for any given GPS coordinates and text address
     */
    public static function resolveLocation(?float $lat, ?float $lng, string $address = '', string $rawDistrict = '', string $rawUpazilla = ''): array {
        $cleanDistrict = trim($rawDistrict);
        $cleanUpazilla = trim($rawUpazilla);
        $cleanAddress = strtolower($address);

        // 1. Text keyword hints in address or road_name
        if (strpos($cleanAddress, 'kuet') !== false || strpos($cleanAddress, 'teligati') !== false || strpos($cleanAddress, 'fulbarigate') !== false) {
            return [
                'division' => 'Khulna',
                'district' => 'Khulna',
                'upazilla' => 'Khan Jahan Ali'
            ];
        }

        if (strpos($cleanAddress, 'kushtia') !== false || strpos($cleanAddress, 'jhenaidah hwy') !== false) {
            return [
                'division' => 'Khulna',
                'district' => 'Kushtia',
                'upazilla' => 'Kushtia Sadar'
            ];
        }

        if (strpos($cleanAddress, 'mirpur') !== false) {
            // Check if coordinates indicate Dhaka or Kushtia (Mirpur is in both)
            if ($lat !== null && $lat > 23.5 && $lng > 90.0) {
                return ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Mirpur'];
            }
        }

        // 2. If lat & lng are available, perform nearest centroid / distance check
        if ($lat !== null && $lng !== null && $lat > 20.0 && $lat < 27.0 && $lng > 88.0 && $lng < 93.0) {
            $bestMatch = null;
            $minDist = PHP_FLOAT_MAX;

            foreach (self::getCentroids() as $c) {
                // Approximate Euclidean distance in degrees (sufficient for sub-district proximity in BD)
                $d = sqrt(pow($lat - $c['lat'], 2) + pow($lng - $c['lng'], 2));
                if ($d < $minDist) {
                    $minDist = $d;
                    $bestMatch = $c;
                }
            }

            // If the closest match is within reasonable proximity (~15-20km, approx 0.18 degrees)
            if ($bestMatch && $minDist <= 0.25) {
                return [
                    'division' => $bestMatch['division'],
                    'district' => $bestMatch['district'],
                    'upazilla' => $bestMatch['upazilla']
                ];
            }

            // General Regional Fallback by Bounding Box
            if ($lat < 23.4 && $lng < 89.8) {
                return ['division' => 'Khulna', 'district' => 'Khulna', 'upazilla' => 'Khan Jahan Ali'];
            } elseif ($lat >= 23.4 && $lat < 24.3 && $lng >= 90.0 && $lng < 91.0) {
                return ['division' => 'Dhaka', 'district' => 'Dhaka', 'upazilla' => 'Mirpur'];
            } elseif ($lat < 23.0 && $lng >= 91.5) {
                return ['division' => 'Chattogram', 'district' => 'Chattogram', 'upazilla' => 'Kotwali'];
            }
        }

        // 3. Fallback to default operations zone
        return [
            'division' => 'Khulna',
            'district' => 'Khulna',
            'upazilla' => 'Khan Jahan Ali'
        ];
    }

    /**
     * Get representative coordinates for any Upazilla or District
     */
    public static function getCoordinatesForUpazilla(string $upazilla, string $district = ''): array {
        foreach (self::getCentroids() as $c) {
            if (strcasecmp($c['upazilla'], $upazilla) === 0) {
                if (empty($district) || strcasecmp($c['district'], $district) === 0) {
                    return ['lat' => $c['lat'], 'lng' => $c['lng']];
                }
            }
        }
        $distMap = [
            'Khulna' => ['lat' => 22.8456, 'lng' => 89.5403],
            'Kushtia' => ['lat' => 23.9013, 'lng' => 89.1205],
            'Dhaka' => ['lat' => 23.8103, 'lng' => 90.4125],
            'Jashore' => ['lat' => 23.1667, 'lng' => 89.2167],
            'Chattogram' => ['lat' => 22.3569, 'lng' => 91.7832],
            'Rajshahi' => ['lat' => 24.3636, 'lng' => 88.6241],
            'Barishal' => ['lat' => 22.7010, 'lng' => 90.3535],
            'Sylhet' => ['lat' => 24.8949, 'lng' => 91.8687],
            'Rangpur' => ['lat' => 25.7439, 'lng' => 89.2752],
            'Mymensingh' => ['lat' => 24.7471, 'lng' => 90.4203]
        ];
        if (!empty($district) && isset($distMap[$district])) {
            return $distMap[$district];
        }
        return ['lat' => 22.8985, 'lng' => 89.5003];
    }
}
